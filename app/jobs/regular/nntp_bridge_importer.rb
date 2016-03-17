module Jobs
  class NntpBridgeImporter < Jobs::Base
    @@active_importers = []

    def execute(args)
      newsgroup = args[:newsgroup]
      unless @@active_importers.include? newsgroup
        @@active_importers << newsgroup
        begin
          DiscourseNntpBridge::NewsgroupImporter.new(quiet: ENV['QUIET'].present?).sync! newsgroup
        ensure
          @@active_importers.delete(newsgroup)
        end
      end
    end
  end
end
