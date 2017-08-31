require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe DiscourseNntpBridge::PostImporter do
  subject { DiscourseNntpBridge::PostImporter.new }

  describe '.find_user_from_article' do
    let!(:article) { DiscourseNntpBridge::PostImporter::Article.new }

    context 'with a known author' do
      let!(:user) { Fabricate(:user, email: "test@example.com", name: "Test User") }

      context 'with only a valid author_email' do
        before { article.author_email = "test@example.com" }

        it 'finds the user' do
          found_user = subject.send(:find_user_from_article, article)
          expect(found_user).to eq(user)
        end
      end

      context 'with only a valid author_name' do
        before { article.author_name = "Test User" }

        it 'finds the user' do
          found_user = subject.send(:find_user_from_article, article)
          expect(found_user).to eq(user)
        end
      end

      context 'with only an unparsed author_raw that has an email' do
        before { article.author_raw = "test@example.com" }

        it 'finds the user' do
          found_user = subject.send(:find_user_from_article, article)
          expect(found_user).to eq(user)
        end
      end

      context 'with only an unparsed author_raw that has a name' do
        before { article.author_raw = "Test User" }

        it 'finds the user' do
          found_user = subject.send(:find_user_from_article, article)
          expect(found_user).to eq(user)
        end
      end
    end

    context 'with an unkown author' do
      before do
        SiteSetting.load_settings(File.join(Rails.root, 'plugins', 'discourse-nntp-bridge', 'config', 'settings.yml'))
        article.body = "Hello world!"
        article.author_raw = "I don't exist"
      end

      context 'with the default bridge settings' do
        let!(:user) { User.find_by(username: "system") }
        let!(:found_user) { subject.send(:find_user_from_article, article) }

        it 'uses the system user' do
          expect(found_user).to eq(user)
        end

        it 'prepends the body with a notice' do
          expect(article.body).to eq("*Post from NNTP guest I don't exist*\n\nHello world!")
        end
      end

      context 'with a custom guest username set' do
        before do
          Fabricate(:user, username: "my_guest", email: "my_guest@example.com", name: "Guest Account")
          SiteSetting.nntp_bridge_guest_username = "my_guest"
        end

        let!(:user) { User.find_by(username: "my_guest") }
        let!(:found_user) { subject.send(:find_user_from_article, article) }

        it 'uses the custom set user' do
          expect(found_user).to eq(user)
        end

        it 'prepends the body with a notice' do
          expect(article.body).to eq("*Post from NNTP guest I don't exist*\n\nHello world!")
        end
      end
    end
  end
end
