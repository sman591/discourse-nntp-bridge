# frozen_string_literal: true

module DiscourseNntpBridge
  class NewsgroupImporter
    def initialize(quiet: false)
      @server = Server.new
      @importer = PostImporter.new(quiet: quiet)
    end

    def sync_all!
      return unless SiteSetting.nntp_bridge_enabled?

      newsgroups = CategoryCustomField.where(name: 'nntp_bridge_newsgroup').pluck(:value).reverse

      newsgroups.each do |newsgroup|
        sync! newsgroup
      end

      puts if File.basename($PROGRAM_NAME) == 'rake'
    end

    def sync!(newsgroup)
      return unless SiteSetting.nntp_bridge_enabled?

      local_message_ids = NntpPost.pluck(:message_id)
      remote_message_ids = @server.message_ids([newsgroup])
      # message_ids_to_destroy = local_message_ids - remote_message_ids
      ignore_ids = SiteSetting.nntp_bridge_ignore_messages.split(',').collect(&:strip)

      message_ids_to_import = remote_message_ids - local_message_ids - ignore_ids

      # if message_ids_to_destroy.any?
      #   puts "Deleting #{message_ids_to_destroy.size} posts" if File.basename($0) == 'rake'
      #   Post.where(id: message_ids_to_destroy).destroy_all
      # end

      puts
      puts "Importing #{message_ids_to_import.size} posts from #{newsgroup}" if File.basename($PROGRAM_NAME) == 'rake'
      message_ids_to_import.each do |message_id|
        @importer.import!(@server.article(message_id), newsgroup)
        print '.' if File.basename($PROGRAM_NAME) == 'rake'
      end
    end
  end
end
