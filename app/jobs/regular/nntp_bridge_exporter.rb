module Jobs
  class NntpBridgeExporter < Jobs::Base
    def execute(args)
      puts "*Post Exporter: #{args[:post_id]}*"
      post = Post.find(args[:post_id])
      if not post
        return
      end
      DiscourseNntpBridge.create_article_from_post post
    end
  end
end
