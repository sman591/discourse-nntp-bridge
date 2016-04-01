require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe Jobs::NntpBridgeImportScheduler do

  describe "enqueue" do
    it "should support enqueue" do
      Jobs.enqueue(:nntp_bridge_import_scheduler)
    end
  end

end
