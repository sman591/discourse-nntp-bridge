module Jobs
  class NntpBridgeImporter < Jobs::Base
    @@active_importers = []

    def execute(args)
      newsgroup = args[:newsgroup]
      return if self.class.is_active? newsgroup
      @@active_importers << newsgroup
      begin
        DiscourseNntpBridge::NewsgroupImporter.new(quiet: ENV['QUIET'].present?).sync! newsgroup
      ensure
        @@active_importers.delete(newsgroup)
      end
    end

    def self.is_active?(newsgroup)
      @@active_importers.include? newsgroup
    end
  end
end
