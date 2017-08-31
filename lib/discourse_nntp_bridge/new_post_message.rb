module DiscourseNntpBridge
  class NewPostMessage < BasicMessage
    attribute :body, type: String, default: ''
    attribute :followup_newsgroup_id, type: String
    attribute :newsgroup_ids, type: String, default: ''
    attribute :parent_id, type: String, default: nil
    attribute :subject, type: String

    validates :newsgroup_ids, :subject, presence: true
    # validate :followup_newsgroup_must_exist
    # validate :newsgroups_must_exist_and_allow_posting
    # validate :parent_must_exist

    private

    def to_mail
      mail = super
      mail.subject, mail.body = subject, body
      mail = FlowedFormat.encode_message(mail)

      mail.header['Newsgroups'] = newsgroup_ids
      if parsed_newsgroup_ids.size > 1
        mail.header['Followup-To'] = followup_newsgroup.id
      end

      if parent.present?
        # Mail gem does not automatically wrap Message-IDs in brackets
        mail.references = [
          parent_message
        ].flatten.compact.map{ |message_id| "<#{message_id}>" }
      end

      mail
    end

    def newsgroups
      @newsgroups ||= Newsgroup.where(id: parsed_newsgroup_ids)
    end

    def parsed_newsgroup_ids
      @parsed_newsgroup_ids ||= newsgroup_ids.split(',')
    end

    def followup_newsgroup
      @followup_newsgroup ||= Newsgroup.find_by(id: followup_newsgroup_id)
    end

    def parent_message
      @parent_message ||= parent.present? ? parent_id : nil
    end

    def parent
      @parent ||= parent_id
    end

    def followup_newsgroup_must_exist
      if parsed_newsgroup_ids.size > 1
        if followup_newsgroup_id.blank?
          errors.add(:followup_newsgroup_id, 'must be provided if posting to multiple newsgroups')
        elsif followup_newsgroup.blank?
          errors.add(:followup_newsgroup_id, 'specifies a nonexistent newsgroup')
        end
      end
    end

    def newsgroups_must_exist_and_allow_posting
      if newsgroups.size != parsed_newsgroup_ids.size
        errors.add(:newsgroup_ids, 'specifies one or more nonexistent newsgroups')
      elsif newsgroups.size != newsgroups.where_posting_allowed.size
        errors.add(:newsgroup_ids, 'specifies one or more read-only newsgroups')
      end
    end

    def parent_must_exist
      if parent_id.present? && parent.blank?
        errors.add(:parent_id, 'specifies a nonexistent post')
      end
    end
  end
end
