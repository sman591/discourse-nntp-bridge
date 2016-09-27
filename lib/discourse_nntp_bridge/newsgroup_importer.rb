module DiscourseNntpBridge
  class NewsgroupImporter
    def initialize(quiet: false)
      @server = Server.new
      @importer = PostImporter.new(quiet: quiet)
    end

    def ignore_ids
      SiteSetting.nntp_bridge_ignore_messages.split(",").collect(&:strip)
    end

    def sync_all!
      return unless SiteSetting.nntp_bridge_enabled?

      newsgroups = CategoryCustomField.where(name: "nntp_bridge_newsgroup").pluck(:value).reverse

      newsgroups.each do |newsgroup|
        sync! newsgroup
      end

      puts if File.basename($0) == 'rake'
    end

    def sync!(newsgroup)
      return unless SiteSetting.nntp_bridge_enabled?

      return sync_cancel! if (newsgroup == "control.cancel")

      local_message_ids = NntpPost.pluck(:message_id)
      remote_message_ids = @server.message_ids([newsgroup])

      message_ids_to_import = remote_message_ids - local_message_ids - ignore_ids

      puts
      puts "Importing #{message_ids_to_import.size} posts from #{newsgroup}" if File.basename($0) == 'rake'
      message_ids_to_import.each do |message_id|
        @importer.import!(@server.article(message_id), newsgroup)
        print '.' if File.basename($0) == 'rake'
      end
    end

    def sync_cancel!
      puts "SYNCING CANCEL"
      return unless SiteSetting.nntp_bridge_enabled?

      local_message_ids = NntpPost.pluck(:message_id)
      cancel_message_ids = @server.message_ids(["control.cancel"]) - ignore_ids

      # message_ids_to_destroy = local_message_ids & cancel_message_ids - ignore_ids
      message_ids_to_destroy = cancel_message_ids

      puts "Deleting #{message_ids_to_destroy.size} posts"
      puts message_ids_to_destroy

      message_ids_to_destroy.each do |message_id|
        @importer.import!(@server.article(message_id), "control.cancel")
        print '.'
      end

      # DiscourseNntpBridge::NntpPost.where(message_id: message_ids_to_destroy).each do |nntp_post|
      #   print '.' if File.basename($0) == 'rake'
      #   PostDestroyer.new(Discourse.system_user, nntp_post.post).destroy
      # end
    end
  end
end
