module Jobs
  class NntpBridgeExporter < Jobs::Base
    def execute(args)
      post = Post.find(args[:post_id])
      return if not post
      DiscourseNntpBridge.create_article_from_post post
    end
  end
end
