# name: discourse-nntp-bridge
# about: Discourse plugin to keep NNTP & Discourse in sync
# version: 0.0.1
# authors: Stuart Olivera
# url: https://github.com/sman591/discourse-nntp-bridge

enabled_site_setting :nntp_bridge_enabled


# install dependencies
gem 'active_attr', '0.9.0'
gem 'thoughtafter-nntp', '1.0.0.3', require: false
gem 'rfc2047', '0.3', github: 'ConradIrwin/rfc2047-ruby'

require 'nntp'

# load the engine
load File.expand_path('../lib/discourse_nntp_bridge.rb', __FILE__)
load File.expand_path('../lib/discourse_nntp_bridge/engine.rb', __FILE__)

ENV['NEWS_HOST'] = ''
ENV['NEWS_USERNAME'] = ''
ENV['NEWS_PASSWORD'] = ''

after_initialize do

  class DiscourseNntpBridge::NntpPost < ActiveRecord::Base
    belongs_to :post

    validates :post_id, :message_id, presence: true
  end

  Post.class_eval do
    has_many :nntp_posts, class_name: 'DiscourseNntpBridge::NntpPost', dependent: :destroy
  end

  on(:post_created) do |post|
    create(post)
  end
end

def create(post)
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

  newsgroup_ids = post.topic.category.custom_fields["nntp_bridge_newsgroup"] || SiteSetting.nntp_bridge_default_newsgroup

  new_post_params = {
    body: post.raw,
    parent_id: parent_id,
    newsgroup_ids: newsgroup_ids,
    subject: title,
    user: post.user,
  }
  puts "\n\nNNTP: **********************\n"
  message = NNTP::NewPostMessage.new(new_post_params)
  puts message.valid?
  message_id = message.transmit
  if message_id.present?
    DiscourseNntpBridge::NntpPost.create(post: post, message_id: message_id)
  else
    puts "\nNO MESSAGE ID RETURNED\n"
  end
  puts "\n/NNTP **********************\n\n\n\n\n\n\n\n\n"

end
