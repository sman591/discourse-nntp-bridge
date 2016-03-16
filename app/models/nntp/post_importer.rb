module NNTP
  class PostImporter
    def initialize(quiet: false)
      @quiet = quiet
    end

    def import!(article:, newsgroup:, post: Post.new)
      ActiveRecord::Base.transaction do
        update_post_from_article(article, post, newsgroup)
        # process_subscriptions(post) unless @quiet
      end

      post
    end

    private

    def create_article_from_nntp(message, newsgroup)
      article = Article.new
      article.message = message
      mail = Mail.new(article.message)

      article.message_id = mail.message_id
      article.author_raw = header_from_message(mail, 'From')
      article.author_name = author_name_from_message(mail)
      article.author_email = author_email_from_message(mail)
      article.subject = header_from_message(mail, 'Subject')
      article.created_at = date_from_message(mail)

      article.headers, article.body = headers_and_body_from_message(mail)
      threading = guess_threading_for_post(article, newsgroup)

      article.parent = threading.parent
      article.is_dethreaded = !threading.is_correct

      # followup_newsgroup = if mail.header['Followup-To'].present?
      #   Newsgroup.find_by(id: mail.header['Followup-To'].to_s)
      # end

      article
    end

    def update_post_from_article(article, post, newsgroup)
      article = create_article_from_nntp(article, newsgroup)

      user_id = find_user_from_article(article).id
      topic_id = find_or_create_topic_from_article(article, user_id, newsgroup).id

      if article.body.blank?
        article.body = SiteSetting.nntp_bridge_empty_body_replacement.presence || "*(empty body from NNTP)*"
      elsif not TextSentinel.body_sentinel(article.body).valid?
        article.body = SiteSetting.nntp_bridge_invalid_body_replacement.presence || "*(invalid body from NNTP)*"
      end

      post.assign_attributes(
        user_id: user_id,
        topic_id: topic_id,
        created_at: article.created_at,
        updated_at: article.created_at,
        raw: article.body
      )
      begin
        post.save!
      rescue PrettyText::JavaScriptError
        puts "JS error while parsing article #{article.message_id}" if File.basename($0) == 'rake'
        raise ActiveRecord::Rollback
      end
      DiscourseNntpBridge::NntpPost.create!(
        message_id: article.message_id,
        post_id: post.id
      )
    end

    # def process_subscriptions(post)
    #   User.active.each do |user|
    #     if not post.authored_by?(user)
    #       subscriptions = user.subscriptions.for(post.newsgroups)
    #       unread_level = subscriptions.where.not(unread_level: nil).minimum(:unread_level)
    #       unread_level ||= user.default_subscription.unread_level
    #       email_level = subscriptions.where.not(email_level: nil).minimum(:email_level)
    #       email_level ||= user.default_subscription.email_level

    #       potential_unread = Unread.new(user: user, post: post)
    #       personal_level = potential_unread.personal_level

    #       if personal_level >= unread_level
    #         potential_unread.save!
    #       end

    #       if personal_level >= email_level
    #         Mailer.post_notification(post, user).deliver_now
    #       end
    #     end
    #   end
    # end

    def guess_threading_for_post(article, newsgroup)
      guess_threading_from_references(article) ||
        guess_threading_from_subject(article, newsgroup) ||
        Threading.new(nil, true)
    end

    def guess_threading_from_references(article)
      references = Array(Mail.new(article.headers).references)

      if references.present?
        parent_from_references = DiscourseNntpBridge::NntpPost.find_by(message_id: references[-1])
        root_from_references = DiscourseNntpBridge::NntpPost.find_by(message_id: references[0])

        if parent_from_references.present?
          Threading.new(parent_from_references.post.topic, true)
        elsif root_from_references.present?
          Threading.new(root_from_references.post.topic)
        end
      end
    end

    def guess_threading_from_subject(article, newsgroup)
      if article.subject =~ /Re:/i
        topics = category_for_newsgroup(newsgroup).topics
        guessed_topic = topics
          .where(
            'created_at < ? AND created_at > ?',
            article.created_at,
            article.created_at - 3.months
          )
          .where(
            'title = ? OR title = ? OR title = ?',
            article.subject,
            article.subject.sub(/^Re: ?/i, ''),
            article.subject.sub(/^Re: ?(\[.+\] )?/i, '')
          )
          .order(:created_at).first

        if guessed_topic.present?
          Threading.new(guessed_topic)
        end
      end
    end

    # def initialize_postings_for_message(mail)
    #   followup_newsgroup_name = mail.header['Followup-To'].to_s
    #   xrefs = mail.header['Xref'].to_s.split[1..-1].map{ |xref| xref.split(':') }

    #   xrefs.map do |(newsgroup_name, number)|
    #     if Newsgroup.exists?(newsgroup_name)
    #       Posting.new(newsgroup_id: newsgroup_name, number: number)
    #     end
    #   end.compact
    # end

    def header_from_message(mail, header)
      # Mail gem likes to pretend that incorrectly-encoded headers don't exist,
      # so if we still want to salvage something we have to do it ourselves
      utf8_encode(mail.header[header].to_s).presence ||
        utf8_encode(mail.header.raw_source)[/^#{header}: (.*)$/, 1].try(:chomp)
    end

    def author_name_from_message(mail)
      utf8_encode(mail.header['From'].addrs.first.display_name) rescue nil
    end

    def author_email_from_message(mail)
      utf8_encode(mail.header['From'].addrs.first.address) rescue nil
    end

    def date_from_message(mail)
      DATE_HEADERS.map{ |h| mail.header[h] }.compact.first.to_s.to_datetime
    end

    def headers_and_body_from_message(mail)
      target_part = mail
      headers = mail.header.raw_source

      if mail.multipart?
        target_part = mail.text_part.presence || mail.parts.first
        headers << "X-WebNews-Part-Headers-Follow: true\n"
        headers << target_part.header.raw_source
      end

      [
        utf8_encode(headers),
        utf8_encode(FlowedFormat.decode_message(target_part))
      ]
    end

    def utf8_encode(text)
      text.encode('UTF-8', invalid: :replace, undef: :replace)
    end

    def category_for_newsgroup(newsgroup)
      CategoryCustomField.where(
        name: "nntp_bridge_newsgroup",
        value: newsgroup
      ).first.category
    end

    def find_user_from_article(article)
      user = User.where(email: article.author_email).first ||
        User.where(name: article.author_name).first ||
        User.where(email: article.author_raw).first ||
        User.where(name: article.author_raw).first

      if not user
        article.body.prepend "#{SiteSetting.nntp_bridge_guest_notice.gsub("{author}", article.author_raw)}\n\n"
        if username = SiteSetting.nntp_bridge_guest_username? && username.present?
          user = User.where(username: username).first
        end
      end

      user = User.find(-1) if not user

      user
    end

    def find_or_create_topic_from_article(article, user_id, newsgroup)
      if article.is_dethreaded
        article.body.prepend "#{SiteSetting.nntp_bridge_dethreaded_notice}\n\n"
      end

      return article.parent if article.parent

      # todo: probably better to do this in a begin/rescue as this only happens to a select number of posts

      old_subject = article.subject
      subject = article.subject

      if not TextSentinel.title_sentinel(subject).valid?
        if SiteSetting.nntp_bridge_override_title_validations?
          subject = "Temporary subject for complexity reasons"
          # todo: this could error if the site doesn't allow duplicate titles
        else
          puts if File.basename($0) == 'rake'
          puts "Invalid subject from message #{article.message_id}, skipping" if File.basename($0) == 'rake'
          raise ActiveRecord::Rollback
        end
      end

      topic = Topic.create!(
        title: subject[0...SiteSetting.max_topic_title_length],
        user_id: user_id,
        category_id: category_for_newsgroup(newsgroup).id,
        created_at: article.created_at,
        updated_at: article.created_at
      )

      if !TextSentinel.title_sentinel(old_subject).valid? && SiteSetting.nntp_bridge_override_title_validations?
        topic.update_attribute(:title, old_subject)
      end

      topic
    end

    DATE_HEADERS = ['Injection-Date', 'NNTP-Posting-Date', 'Date']
    Threading = Struct.new(:parent, :is_correct)
    Article = Struct.new(
      :message,
      :message_id,
      :headers,
      :body,
      :author_raw,
      :author_name,
      :author_email,
      :subject,
      :created_at,
      :parent,
      :is_dethreaded
    )
  end
end
