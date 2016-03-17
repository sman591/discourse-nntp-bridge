module Jobs
  class NntpBridgeImportScheduler < Jobs::Scheduled
    every 1.minute

    def execute(newsgroup)
      newsgroups = CategoryCustomField.where(name: "nntp_bridge_newsgroup").pluck(:value)

      newsgroups.each do |newsgroup|
        Jobs.enqueue(:nntp_bridge_importer, newsgroup: newsgroup)
      end
    end
  end
end
