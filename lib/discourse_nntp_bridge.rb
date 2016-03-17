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

    newsgroup_ids = post.topic.category.custom_fields["nntp_bridge_newsgroup"].presence || SiteSetting.nntp_bridge_default_newsgroup

    new_post_params = {
      body: post.raw,
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

  private
end
