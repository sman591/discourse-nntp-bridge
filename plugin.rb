# name: discourse-nntp-bridge
# about: Discourse plugin to keep NNTP & Discourse in sync
# version: 0.0.1
# authors: Stuart Olivera

gem 'active_attr', '0.9.0'
gem 'thoughtafter-nntp', '1.0.0.3', require: false
gem 'rfc2047', '0.3', github: 'ConradIrwin/rfc2047-ruby'

require 'nntp'

NEWSGROUPS = ''
ENV['NEWS_HOST'] = ''
ENV['NEWS_USERNAME'] = ''
ENV['NEWS_PASSWORD'] = ''

NNTP_CUSTOM_FIELD ||= "nntp_id".freeze

after_initialize do
  on(:post_created) do |post|
    create(post)
  end
end

def create(post)
  require './plugins/discourse-nntp-bridge/app/models/nntp/basic_message'
  require './plugins/discourse-nntp-bridge/app/models/nntp/flowed_format'
  require './plugins/discourse-nntp-bridge/app/models/nntp/new_post_message'
  require './plugins/discourse-nntp-bridge/app/models/nntp/newsgroup_importer'
  require './plugins/discourse-nntp-bridge/app/models/nntp/post_importer'
  require './plugins/discourse-nntp-bridge/app/models/nntp/server'
  title = post.is_first_post? ? post.topic.title : "Re: " + post.topic.title
  new_post_params = {
    body: post.raw,
    followup_newsgroup_id: post.topic.custom_fields[NNTP_CUSTOM_FIELD] || "",
    newsgroup_ids: NEWSGROUPS,
    subject: title,
    user: post.user,
  }
  puts "\n\nNNTP: **********************\n"
  message = NNTP::NewPostMessage.new(new_post_params)
  puts message.valid?
  message_id = message.transmit
  if message_id.present?
    post.custom_fields[NNTP_CUSTOM_FIELD] = message_id
    post.save_custom_fields(true)
  else
    puts "\nNO MESSAGE ID RETURNED\n"
  end
  puts "\n/NNTP **********************\n\n\n\n\n\n\n\n\n"

end
