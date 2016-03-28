require "rails_helper"

if ENV['RUN_COVERAGE']
  require 'simplecov'
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.configure do |config|
    config.path_prefix = "discourse" #the root of your Rails application relative to the repository root
    config.git_dir = "plugins/discourse-nntp-bridge" #the relative or absolute location of your git root compared to where your tests are run
  end
  SimpleCov.add_filter "discourse/app"
  SimpleCov.add_filter "discourse/lib"
  CodeClimate::TestReporter.start
  FakeWeb.allow_net_connect = %r[^https?://codeclimate.com]
end

path = "./plugins/discourse-nntp-bridge/plugin.rb"
source = File.read(path)
plugin = Plugin::Instance.new(Plugin::Metadata.parse(source), path)
plugin.activate!
plugin.initializers.first.call
