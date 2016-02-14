module NNTP
  class NewsgroupImporter
    def initialize(quiet: false)
      @server = Server.new
      @importer = PostImporter.new(quiet: quiet)
    end

    def sync_all!
      print 'Waiting for sync lock... ' if $in_rake

      Flag.with_news_sync_lock(full_sync: true) do
        puts 'OK' if $in_rake

        local_names = Newsgroup.ids
        remote_newsgroups = @server.newsgroups
        remote_names = remote_newsgroups.map(&:name)
        names_to_destroy = local_names - remote_names
        names_to_create = remote_names - local_names

        if names_to_destroy.any?
          puts "Deleting newsgroups: #{names_to_destroy.join(', ')}" if $in_rake
          Newsgroup.where(id: names_to_destroy).destroy_all
        end

        if names_to_create.any?
          puts "Creating newsgroups: #{names_to_create.join(', ')}" if $in_rake
        end

        remote_newsgroups.each do |remote_newsgroup|
          Newsgroup.find_or_initialize_by(id: remote_newsgroup.name).update!(
            description: remote_newsgroup.description,
            status: remote_newsgroup.status
          )
        end

        sync!
      end
    end

    def sync!(newsgroups = [])
      Flag.with_news_sync_lock do
        local_message_ids = if newsgroups.any?
          Post.joins(:postings)
            .where(postings: { newsgroup_id: newsgroups.map(&:id) }).ids
        else
          Post.ids
        end
        remote_message_ids = @server.message_ids(newsgroups.map(&:id))
        message_ids_to_destroy = local_message_ids - remote_message_ids
        message_ids_to_import = remote_message_ids - local_message_ids

        if message_ids_to_destroy.any?
          puts "Deleting #{message_ids_to_destroy.size} posts" if $in_rake
          Post.where(id: message_ids_to_destroy).destroy_all
        end

        puts "Importing #{message_ids_to_import.size} posts" if $in_rake
        message_ids_to_import.each do |message_id|
          @importer.import!(article: @server.article(message_id))
          print '.' if $in_rake
        end

        puts if $in_rake
      end
    end
  end
end
