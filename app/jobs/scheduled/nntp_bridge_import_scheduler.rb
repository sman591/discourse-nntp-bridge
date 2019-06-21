# frozen_string_literal: true

module Jobs
  class NntpBridgeImportScheduler < Jobs::Scheduled
    every 1.minute

    def execute(_args)
      newsgroups = CategoryCustomField.where(name: 'nntp_bridge_newsgroup').pluck(:value)

      newsgroups.each do |newsgroup|
        next if Jobs::NntpBridgeImporter.is_active?(newsgroup) || self.class.importer_queued?(newsgroup)

        Jobs.enqueue(:nntp_bridge_importer, newsgroup: newsgroup)
      end
    end

    def self.importer_queued?(newsgroup)
      queries = [
        proc { Sidekiq::Queue.new },
        proc { Sidekiq::RetrySet.new }
      ]
      queries.any? do |query|
        query.call.any? do |job|
          job.klass == 'Jobs::NntpBridgeImporter' &&
            job.args[0]['newsgroup'] == newsgroup
        end
      end
    end
  end
end
