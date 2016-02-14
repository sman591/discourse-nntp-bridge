module NNTP
  class PostImporter
    def initialize(quiet: false)
      @quiet = quiet
    end

    def import!(article:, post: Post.new)
      post_exists = post.persisted?

      Post.transaction do
        update_post_from_article(article, post)
        process_subscriptions(post) unless @quiet || post_exists
      end

      post
    end

    private

    def update_post_from_article(article, post)
      mail = Mail.new(article)

      created_at = date_from_message(mail)
      headers, body = headers_and_body_from_message(mail)
      postings = initialize_postings_for_message(mail)
      followup_newsgroup = if mail.header['Followup-To'].present?
        Newsgroup.find_by(id: mail.header['Followup-To'].to_s)
      end

      post.assign_attributes(
        id: mail.message_id,
        subject: header_from_message(mail, 'Subject'),
        author_raw: header_from_message(mail, 'From'),
        author_name: author_name_from_message(mail),
        author_email: author_email_from_message(mail),
        created_at: created_at,
        had_attachments: mail.has_attachments?,
        headers: headers,
        body: body,
        postings: postings,
        followup_newsgroup: followup_newsgroup
      )
      threading = guess_threading_for_post(post)
      post.assign_attributes(
        parent: threading.parent,
        is_dethreaded: !threading.is_correct
      )
      post.save!
    end

    def process_subscriptions(post)
      User.active.each do |user|
        if not post.authored_by?(user)
          subscriptions = user.subscriptions.for(post.newsgroups)
          unread_level = subscriptions.where.not(unread_level: nil).minimum(:unread_level)
          unread_level ||= user.default_subscription.unread_level
          email_level = subscriptions.where.not(email_level: nil).minimum(:email_level)
          email_level ||= user.default_subscription.email_level

          potential_unread = Unread.new(user: user, post: post)
          personal_level = potential_unread.personal_level

          if personal_level >= unread_level
            potential_unread.save!
          end

          if personal_level >= email_level
            Mailer.post_notification(post, user).deliver_now
          end
        end
      end
    end

    def guess_threading_for_post(post)
      guess_threading_from_references(post) ||
        guess_threading_from_subject(post) ||
        Threading.new(nil, true)
    end

    def guess_threading_from_references(post)
      references = Array(Mail.new(post.headers).references)

      if references.present?
        parent_from_references = Post.find_by(id: references[-1])
        root_from_references = Post.find_by(id: references[0])

        if parent_from_references.present?
          Threading.new(parent_from_references, true)
        elsif root_from_references.present?
          Threading.new(root_from_references)
        end
      end
    end

    def guess_threading_from_subject(post)
      if post.subject =~ /Re:/i
        guessed_root = Post.roots.joins(:postings)
          .where(postings: { newsgroup_id: post.newsgroup_ids })
          .where(
            'created_at < ? AND created_at > ?',
            post.created_at,
            post.created_at - 3.months
          )
          .where(
            'subject = ? OR subject = ? OR subject = ?',
            post.subject,
            post.subject.sub(/^Re: ?/i, ''),
            post.subject.sub(/^Re: ?(\[.+\] )?/i, '')
          )
          .order(:created_at).first

        if guessed_root.present?
          Threading.new(guessed_root)
        end
      end
    end

    def initialize_postings_for_message(mail)
      followup_newsgroup_name = mail.header['Followup-To'].to_s
      xrefs = mail.header['Xref'].to_s.split[1..-1].map{ |xref| xref.split(':') }

      xrefs.map do |(newsgroup_name, number)|
        if Newsgroup.exists?(newsgroup_name)
          Posting.new(newsgroup_id: newsgroup_name, number: number)
        end
      end.compact
    end

    def header_from_message(mail, header)
      # Mail gem likes to pretend that incorrectly-encoded headers don't exist,
      # so if we still want to salvage something we have to do it ourselves
      utf8_encode(mail.header[header].to_s).presence ||
        utf8_encode(mail.header.raw_source).match(/^#{header}: (.*)$/)[1].chomp
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

    DATE_HEADERS = ['Injection-Date', 'NNTP-Posting-Date', 'Date']
    Threading = Struct.new(:parent, :is_correct)
  end
end
