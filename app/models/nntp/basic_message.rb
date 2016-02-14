module NNTP
  class BasicMessage
    include ActiveAttr::Model
    include ActiveModel::ForbiddenAttributesProtection

    attr_reader :was_accepted

    attribute :user, type: Object

    validates! :user, presence: true

    def transmit
      return if was_accepted
      return unless valid?

      message_id = begin
        Server.new.post(to_mail.to_s)
      rescue Net::NNTPError
        errors.add(:nntp, $!.message)
        nil
      end

      return message_id
      # if message_id.present?
      #   @was_accepted = true

      #   begin
      #     NNTP::NewsgroupImporter.new.sync!(newsgroups)
      #   rescue
      #     ExceptionNotifier.notify_exception($!)
      #   end

      #   Post.find_by(id: message_id)
      # end
    end

    private

    def to_mail
      mail = Mail.new(from: from_line)

      mail.header['User-Agent'] = 'CSH Discourse'

      mail
    end

    def from_line
      address = Mail::Address.new
      address.display_name = user.name
      address.address = user.email
      address.to_s
    end

    def newsgroups
      raise 'must be implemented in subclass'
    end
  end
end
