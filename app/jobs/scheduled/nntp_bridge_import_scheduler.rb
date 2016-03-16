module Jobs
  class NntpBridgeImportScheduler < Jobs::Scheduled
    every 1.minute

    def execute(newsgroup)
      newsgroups = CategoryCustomField.where(name: "nntp_bridge_newsgroup").pluck(:value).reverse

      newsgroups.each do |newsgroup|
        Jobs::NntpBridgeImporter.perform_async(newsgroup: newsgroup)
      end
    end
  end
end
