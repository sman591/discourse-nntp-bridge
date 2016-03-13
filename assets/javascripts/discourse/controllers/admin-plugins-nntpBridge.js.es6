import NntpNewsgroup from 'discourse/plugins/discourse-nntp-bridge/admin/models/nntp-newsgroup';

function genericError() {
  bootbox.alert(I18n.t('generic_error'));
}

export default Ember.ArrayController.extend({
  sortProperties: ["id"],
  sortAscending: true,
  enabled: false,
  performingAction: false,

  actions: {
    refresh() {
      var self = this;
      self.set('performingAction', true);
      NntpNewsgroup.findAll().then(function(result) {
        self.set('stats', result.stats);
        self.set('model', result.posts);
      }).catch(genericError).finally(function() {
        self.set('performingAction', false);
      });
    },

    confirmSpamPost(post) {
      var self = this;
      self.set('performingAction', true);
      NntpNewsgroup.confirmSpam(post).then(function() {
        self.removeObject(post);
        self.incrementProperty('stats.confirmed_spam');
        self.decrementProperty('stats.needs_review');
      }).catch(genericError).finally(function() {
        self.set('performingAction', false);
      });
    },

    allowPost(post) {
      var self = this;
      self.set('performingAction', true);
      NntpNewsgroup.allow(post).then(function() {
        self.incrementProperty('stats.confirmed_ham');
        self.decrementProperty('stats.needs_review');
        self.removeObject(post);
      }).catch(genericError).finally(function() {
        self.set('performingAction', false);
      });
    },

    deleteUser(post) {
      var self = this;
      bootbox.confirm(I18n.t('akismet.delete_prompt', {username: post.get('username')}), function(result) {
        if (result === true) {
          self.set('performingAction', true);
          NntpNewsgroup.deleteUser(post).then(function() {
            self.removeObject(post);
            self.incrementProperty('stats.confirmed_spam');
            self.decrementProperty('stats.needs_review');
          }).catch(genericError).finally(function() {
            self.set('performingAction', false);
          });
        }
      });
    },

    dismiss(post) {
      this.set('performingAction', true);
      NntpNewsgroup.dismiss(post).then(() => {
        this.removeObject(post);
      }).catch(genericError).finally(() => {
        this.set('performingAction', false);
      });
    }

  }
});
