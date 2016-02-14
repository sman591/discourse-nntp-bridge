module NNTP
  class Server
    def newsgroups
      nntp.list[1].map(&:split).map do |fields|
        RemoteNewsgroup.new.tap do |n|
          n.name = fields[0]
          n.status = fields[3]
          n.description = newsgroup_descriptions[n.name]
        end
      end
    end

    def message_ids(newsgroup_names = [])
      wildmat = newsgroup_names.any? ? newsgroup_names.join(',') : '*'
      nntp.newnews(wildmat, '19700101', '000000')[1].uniq.map{ |message_id| message_id[1..-2] }
    end

    def article(message_id)
      # nntp-lib calls sprintf with this parameter internally, so any percent
      # signs in the Message-ID must be doubled
      nntp.article("<#{message_id.sub('%', '%%')}>")[1].join("\n")
    end

    def post(message)
      nntp.post(message)[1][/<(.*?)>/, 1] # Errors should be handled by caller
    end

    private

    def newsgroup_descriptions
      @newsgroup_descriptions ||=
        nntp.list('newsgroups')[1].map{ |line| line.split(/\t+/) }.to_h
    end

    def nntp
      # Hack to get around nntp-lib trying to authenticate twice in `start`
      # TODO: Figure out why only `original` auth works, it's rather insecure
      @nntp ||= Net::NNTP.start(ENV['NEWS_HOST']).tap do |nntp|
        nntp.send(:authenticate, ENV['NEWS_USERNAME'], ENV['NEWS_PASSWORD'], :original)
      end
    end

    RemoteNewsgroup = Struct.new(:name, :description, :status)
  end
end
