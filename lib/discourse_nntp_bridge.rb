module DiscourseNntpBridge
  def self.create_article_from_post(post)
    return unless SiteSetting.nntp_bridge_enabled?

    return if post.topic.private_message?

    if post.is_first_post?
      title = post.topic.title
      parent_id = nil
    else
      title = "Re: " + post.topic.title
      parent_id = NntpPost.where(post_id: post.topic.first_post.id).first.message_id
    end

    body = convert_post_body_quotes post.raw
    newsgroup_ids = post.topic.category.custom_fields["nntp_bridge_newsgroup"].presence || SiteSetting.nntp_bridge_default_newsgroup

    new_post_params = {
      body: body,
      parent_id: parent_id,
      newsgroup_ids: newsgroup_ids,
      subject: title,
      user: post.user,
    }
    message = NewPostMessage.new(new_post_params)
    message_id = message.transmit
    if message_id.present?
      NntpPost.create(post: post, message_id: message_id)
    else
      puts "No message ID returned when posting post #{post.id} to NNTP"
    end
  end

  # private

  def self.convert_post_body_quotes(body)
    converted_body = ""
    body.split("[/quote]").each do |section|
      section.sub! /\n\z/, ''
      matches = /\[quote.*\]\n*(.*)/m.match section
      if not matches
        converted_body << section
        next
      end
      quoted_text = ""
      matches[1].lines.each { |line| quoted_text << "> #{line}" }
      section.sub! matches[0], quoted_text
      converted_body << section
    end
    converted_body
  end
end
