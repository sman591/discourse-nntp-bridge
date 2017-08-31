require 'rails_helper'

if ENV['RUN_COVERAGE']
  require 'simplecov'
  SimpleCov.add_filter 'discourse/app'
  SimpleCov.add_filter 'discourse/lib'
  SimpleCov.start
end

path = './plugins/discourse-nntp-bridge/plugin.rb'
source = File.read(path)
plugin = Plugin::Instance.new(Plugin::Metadata.parse(source), path)
plugin.activate!
plugin.initializers.first.call

require './plugins/discourse-nntp-bridge/app/jobs/regular/nntp_bridge_exporter'
require './plugins/discourse-nntp-bridge/app/jobs/regular/nntp_bridge_importer'
require './plugins/discourse-nntp-bridge/app/jobs/scheduled/nntp_bridge_import_scheduler'
