# frozen_string_literal: true

module Jobs
  class NntpBridgeExporter < Jobs::Base
    def execute(args)
      post = Post.find(args[:post_id])
      return unless post

      DiscourseNntpBridge.create_article_from_post post
    end
  end
end
