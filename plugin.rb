# name: discourse-nntp-bridge
# about: Discourse plugin to keep NNTP & Discourse in sync
# version: 0.1.6
# authors: Stuart Olivera
# url: https://github.com/sman591/discourse-nntp-bridge

enabled_site_setting :nntp_bridge_enabled

# install dependencies
gem 'active_attr', '0.9.0'
gem 'thoughtafter-nntp', '1.0.0.3', require: false
gem 'rfc2047', '0.3', github: 'ConradIrwin/rfc2047-ruby'

if ENV['RUN_COVERAGE']
  gem 'codeclimate-test-reporter', '0.5.0', require: nil
end

require 'nntp'
require_relative 'lib/discourse_nntp_bridge'

after_initialize do

  class DiscourseNntpBridge::NntpPost < ActiveRecord::Base
    belongs_to :post

    validates :post_id, :message_id, presence: true
    validates :message_id, uniqueness: true
  end

  Post.class_eval do
    has_many :nntp_posts, class_name: 'DiscourseNntpBridge::NntpPost', dependent: :destroy
  end

  on(:post_created) do |post|
    require_dependency File.expand_path('../app/jobs/regular/nntp_bridge_exporter.rb', __FILE__)

    Jobs.enqueue(:nntp_bridge_exporter, post_id: post.id)
  end

end
