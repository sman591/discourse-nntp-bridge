module DiscourseNntpBridge
  def self.create_article_from_post(post)
    return unless SiteSetting.nntp_bridge_enabled?

    require './plugins/discourse-nntp-bridge/app/models/nntp/basic_message'
    require './plugins/discourse-nntp-bridge/app/models/nntp/flowed_format'
    require './plugins/discourse-nntp-bridge/app/models/nntp/new_post_message'
    require './plugins/discourse-nntp-bridge/app/models/nntp/newsgroup_importer'
    require './plugins/discourse-nntp-bridge/app/models/nntp/post_importer'
    require './plugins/discourse-nntp-bridge/app/models/nntp/server'

    if post.is_first_post?
      title = post.topic.title
      parent_id = nil
    else
      title = "Re: " + post.topic.title
      parent_id = DiscourseNntpBridge::NntpPost.where(post_id: post.topic.first_post.id).first.message_id
    end

    newsgroup_ids = post.topic.category.custom_fields["nntp_bridge_newsgroup"].presence || SiteSetting.nntp_bridge_default_newsgroup

    new_post_params = {
      body: post.raw,
      parent_id: parent_id,
      newsgroup_ids: newsgroup_ids,
      subject: title,
      user: post.user,
    }
    message = NNTP::NewPostMessage.new(new_post_params)
    message_id = message.transmit
    if message_id.present?
      DiscourseNntpBridge::NntpPost.create(post: post, message_id: message_id)
    else
      puts "No message ID returned when posting post #{post.id} to NNTP"
    end
  end

  private
end
