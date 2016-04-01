require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe Jobs::NntpBridgeImporter do

  describe "enqueue" do
    it "should support enqueue" do
      Jobs.enqueue(:nntp_bridge_importer, newsgroup: "test")
    end
  end

end
