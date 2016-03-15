UNKOWN_USER_ID = -1
$rails_rake_task = true

module DiscourseNntpBridge
  def self.sync_all!
    server = NNTP::Server.new
    CategoryCustomField.where(name: "nntp_bridge_newsgroup").each do |custom_field|
      sync_group!(server, custom_field.value)
    end
  end

  def self.sync_group!(server, name)
    puts server.nntp.group(name)[1] if $rails_rake_task

    category = CategoryCustomField.where(name: "nntp_bridge_newsgroup", value: name).first.category

    my_posts = DiscourseNntpBridge::NntpPost.pluck(:message_id)
    news_posts = server.message_ids([name])
    to_import = news_posts - my_posts

    puts "Importing #{to_import.size} posts." if $rails_rake_task
    to_import.each do |message_id|
      body = server.article(message_id)
      post = import_post!(name, message_id, category, body)
      print '.' if $rails_rake_task
    end
    puts if $rails_rake_task
  end

  def self.import_post!(newsgroup, message_id, category, body)
    stripped = false
    headers = unwrap_headers(body)
    headers.encode!('US-ASCII', invalid: :replace, undef: :replace)

    part_headers, body = multipart_decode(headers, body)
    stripped = true if headers[/^Content-Type:.*mixed/i]

    body = body.unpack('m')[0] if headers[/^Content-Transfer-Encoding: base64/i]
    body = body.unpack('M')[0] if headers[/^Content-Transfer-Encoding: quoted-printable/i]

    if headers[/^Content-Type:.*(X-|unknown)/i]
      body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
    elsif headers[/^Content-Type:.*charset/i]
      body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
    else
      begin
        body.encode!('UTF-8', 'US-ASCII') # RFC 2045 Section 5.2
      rescue
        begin
          body.encode!('UTF-8', 'Windows-1252')
        rescue
          body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
        end
      end
    end

    begin
      if body[/^begin(-base64)? \d{3} /]
        body.gsub!(/^begin \d{3} .*?\nend\n/m, '')
        body.gsub!(/^begin-base64 \d{3} .*?\n====\n/m, '')
        stripped = true
      end
    rescue
      raise "#{x}"
    end

    body = flowed_decode(body) if headers[/^Content-Type:.*format="?flowed"?/i]

    body.rstrip!

    date = Time.parse(
      headers[/^Injection-Date: (.*)/i, 1] ||
      headers[/^NNTP-Posting-Date: (.*)/i, 1] ||
      headers[/^Date: (.*)/i, 1]
    )
    author = header_decode(headers[/^From: (.*)/i, 1])

    matches = /(.+) <(.*)>/.match(author)
    # todo: support "name<test@test.com>" ?
    author_name = matches ? matches[1] : ""
    author_email = matches ? matches[2] : ""

    if author_name.blank?
      if author =~ /.+@.+/
        author_email = author
      else
        author_email = author
        author_name = author
      end
    end

    author_user = User.where(email: author_email).first
    unless author_user
      author_user = User.where(name: author_name).first
    end

    subject = header_decode(headers[/^Subject: (.*)/i, 1])
    message_id = headers[/^Message-ID: <(.*)>/i, 1]
    references = headers[/^References: (.*)/i, 1].to_s.split.map{ |r| r[/<.*>/] }

    parent_id = references[-1] || ''
    thread_id = message_id
    possible_thread_id = references[0] || ''
    possible_thread_id = possible_thread_id[/<(.*)>/i, 1]

    parent = DiscourseNntpBridge::NntpPost.where(message_id: parent_id).first
    possible_parent = DiscourseNntpBridge::NntpPost.where(message_id: possible_thread_id).first

    if parent
      topic_id = parent.post.topic.id
    elsif possible_parent
      topic_id = possible_parent.post.topic.id
    elsif subject =~ /Re:/i
      possible_thread_parent = Topic.where(
        '(title = ? or title = ? or title = ?) and created_at < ? and created_at > ?',
        subject, subject.sub(/^Re: ?/i, ''), subject.sub(/^Re: ?(\[.+\] )?/i, ''), date, date - 3.months
      ).order('created_at').first

      if possible_thread_parent
        topic_id = possible_thread_parent.id
      else
        topic_id = ''
      end
    else
      topic_id = ''
    end

    if topic_id.blank?
      old_subject = subject
      # todo: probably better to do this in a begin/rescue as this only happens to a select number of posts
      unless TextSentinel.title_sentinel(subject).valid?
        puts SiteSetting.nntp_bridge_override_title_validations?
        if SiteSetting.nntp_bridge_override_title_validations?
          subject = "Temporary subject for complexity reasons"
          # todo: this could error if the site doesn't allow duplicate titles
        else
          puts if $rails_rake_task
          puts "Invalid subject from message #{message_id}, skipping" if $rails_rake_task
        end
      end
      topic_id = Topic.create!(
                  title: subject,
                  user_id: author_user.present? ? author_user.id : UNKOWN_USER_ID,
                  category_id: category.present? ? category.id : nil,
                  created_at: date,
                  updated_at: date
                 ).id
      if !TextSentinel.title_sentinel(old_subject).valid? && SiteSetting.nntp_bridge_override_title_validations?
        Topic.find(topic_id).update_attribute(:title, old_subject)
      end
    end

    if body.blank?

    else
      body = body[/.*Xref: [ \w\.:\d]+$?(.*)/m, 1] || body
    end
    body = "(empty body from NNTP)" if body.blank?

    post = Post.create!(
            topic_id: topic_id,
            raw: body,
            user_id: author_user.present? ? author_user.id : UNKOWN_USER_ID,
            created_at: date,
            updated_at: date
           )
    DiscourseNntpBridge::NntpPost.create!(message_id: message_id, post_id: post.id)
    post
  end

  def self.flowed_decode(body)
    new_body_lines = []
    body.each_line do |line|
      line.chomp!
      quotes = line[/^>+/]
      line.sub!(/^>+/, '')
      line.sub!(/^ /, '')
      if line != '-- ' and
          new_body_lines.length > 0 and
          !new_body_lines[-1][/^-- $/] and
          new_body_lines[-1][/ $/] and
          quotes == new_body_lines[-1][/^>+/]
        new_body_lines[-1] << line
      else
        new_body_lines << quotes.to_s + line
      end
    end
    return new_body_lines.join("\n")
  end

  def self.flowed_encode(body)
    body.split("\n").map do |line|
      line.rstrip!
      quotes = ''
      if line[/^>/]
        quotes = line[/^([> ]*>)/, 1].gsub(' ', '')
        line.gsub!(/^[> ]*>/, '')
      end
      line = ' ' + line if line[/^ /]
      if line.length > 78
        line.gsub(/(.{1,#{72 - quotes.length}}|[^\s]+)(\s+|$)/, "#{quotes}\\1 \n").rstrip
      else
        quotes + line
      end
    end.join("\n")
  end

  def self.multipart_decode(headers, body)
    if headers[/^Content-Type: multipart/i]
      boundary = Regexp.escape(headers[/^Content-Type:.*boundary ?= ?"?([^"]+?)"?(;|$)/i, 1])
      match = /.*?#{boundary}\n(.*?)\n\n(.*?)\n(--)?#{boundary}/m.match(body)
      part_headers = unwrap_headers(match[1])
      part_body = match[2]
      return multipart_decode(part_headers, part_body)
    else
      return headers, body
    end
  end

  def self.unwrap_headers(headers)
    headers.gsub(/\n( |\t)/, ' ').gsub(/\t/, ' ')
  end

  def self.header_decode(header)
    begin
      Rfc2047.decode(header)
    rescue Rfc2047::Unparseable
      header
    end
  end

end
