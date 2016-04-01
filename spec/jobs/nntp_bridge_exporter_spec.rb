require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe Jobs::NntpBridgeExporter do

  describe "enqueue" do
    it "should support enqueue" do
      Jobs.enqueue(:nntp_bridge_exporter, post_id: 123)
    end
  end

end
