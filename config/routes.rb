DiscourseNntpBridge::Engine.routes.draw do
  resource :admin_nntp_newsgroups, path: "/", constraints: StaffConstraint.new, only: [:index] do
    collection do
      get    "/"            => "admin_nntp_newsgroups#index"
      get    "index"        => "admin_nntp_newsgroups#index"
      post   "confirm_spam" => "admin_nntp_newsgroups#confirm_spam"
      post   "allow"        => "admin_nntp_newsgroups#allow"
      post   "dismiss"      => "admin_nntp_newsgroups#dismiss"
      delete "delete_user"  => "admin_nntp_newsgroups#delete_user"
    end
  end
end
