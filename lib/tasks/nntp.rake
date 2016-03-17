namespace :nntp do
  desc "Sync all newsgroups, adding unread post data for any new posts"
  task sync: :environment do
    DiscourseNntpBridge::NewsgroupImporter.new(quiet: ENV['QUIET'].present?).sync_all!
  end
end
