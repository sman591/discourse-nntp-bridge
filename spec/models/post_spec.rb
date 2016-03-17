require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe Post do

  it { is_expected.to have_many :nntp_posts }

  describe 'instance' do

    before do
      SiteSetting.load_settings(File.join(Rails.root, 'plugins', 'discourse-nntp-bridge', 'config', 'settings.yml'))
    end

    let!(:post) { Fabricate(:post) }

    it 'destroys NNTP posts when destroyed' do
      DiscourseNntpBridge::NntpPost.create(post_id: post.id, message_id: "abc123@example.com")
      expect {
        post.destroy
      }.to change(DiscourseNntpBridge::NntpPost, :count).by(-1)
    end

  end

end
