export default {
  confirmSpam(post) {
    return Discourse.ajax("/admin/plugins/nntp-bridge/confirm_spam", {
      type: "POST",
      data: {
        post_id: post.get("id")
      }
    });
  },

  allow(post) {
    return Discourse.ajax("/admin/plugins/nntp-bridge/allow", {
      type: "POST",
      data: {
        post_id: post.get("id")
      }
    });
  },

  dismiss(post) {
    return Discourse.ajax("/admin/plugins/nntp-bridge/dismiss", {
      type: "POST",
      data: {
        post_id: post.get("id")
      }
    });
  },

  deleteUser(post) {
    return Discourse.ajax("/admin/plugins/nntp-bridge/delete_user", {
      type: "DELETE",
      data: {
        user_id: post.get("user_id"),
        post_id: post.get("id")
      }
    });
  },

  findAll() {
    return Discourse.ajax("/admin/plugins/nntp-bridge/index.json").then(function(result) {
      result.posts = result.posts.map(p => Discourse.Post.create(p));
      return result;
    });
  }
};
