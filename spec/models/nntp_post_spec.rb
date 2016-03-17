require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe ::DiscourseNntpBridge::NntpPost do

  it { is_expected.to belong_to :post }
  it { is_expected.to validate_presence_of :message_id }
  it { is_expected.to validate_presence_of :post_id }

end
