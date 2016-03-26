require "./plugins/discourse-nntp-bridge/spec/rails_helper"

describe DiscourseNntpBridge do

  subject { DiscourseNntpBridge }

  describe 'create_article_from_post' do

    it 'leaves quote-less body as-is' do
      original_body = "Hello world!\nThis post has no quotes."
      converted_body = subject.convert_post_body_quotes original_body
      expect(converted_body).to eq(original_body)
    end

    it 'converts quotes to simple syntax' do
      original_body = "[quote=\"guest, post:1, topic:1\"]\nThis is a quote\n[/quote]"
      expected_body = "guest wrote:\n> This is a quote"
      converted_body = subject.convert_post_body_quotes original_body
      expect(converted_body).to eq(expected_body)
    end

    it 'converts mid-body quotes to simple syntax' do
      original_body = "The start of my response\n\n[quote=\"guest, post:1, topic:1\"]\nThis is a quote\n[/quote]\n\nThe end of my response"
      expected_body = "The start of my response\n\nguest wrote:\n> This is a quote\n\nThe end of my response"
      converted_body = subject.convert_post_body_quotes original_body
      expect(converted_body).to eq(expected_body)
    end

    it 'removes blank quotes' do
      original_bodies = [
        "[quote=\"guest, post:1, topic:1\"]\n[/quote]",
        "[quote=\"guest, post:1, topic:1\"]\n\n[/quote]"
      ]
      expected_body = ""
      original_bodies.each do |original_body|
        converted_body = subject.convert_post_body_quotes original_body
        expect(converted_body).to eq(expected_body)
      end
    end

    it 'converts multiple quotes to simple syntax' do
      original_body = "[quote=\"guest, post:1, topic:1\"]\nThis is a quote\n[/quote]\n\nThis is my response\n\n[quote=\"admin, post:1, topic:1\"]\nThis is another quote\n[/quote]\n\nThis is my second response"
      expected_body = "guest wrote:\n> This is a quote\n\nThis is my response\n\nadmin wrote:\n> This is another quote\n\nThis is my second response"
      converted_body = subject.convert_post_body_quotes original_body
      expect(converted_body).to eq(expected_body)
    end

    it 'uses author real name' do
      Fabricate(:user, username: "guest", name: "Guest Account")
      original_body = "[quote=\"guest, post:1, topic:1\"]\nThis is a quote\n[/quote]"
      expected_body = "Guest Account wrote:\n> This is a quote"
      converted_body = subject.convert_post_body_quotes original_body
      expect(converted_body).to eq(expected_body)
    end

  end

end
