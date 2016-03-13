import NntpNewsgroup from 'discourse/plugins/discourse-nntp-bridge/admin/models/nntp-newsgroup';

export default Discourse.Route.extend({
  _enabled: false,
  _stats: null,

  model() {
    var self = this;
    return NntpNewsgroup.findAll().then(function(result) {
      self._enabled = result.enabled;
      self._stats = result.stats;
      return result.posts;
    });
  },

  setupController(controller, model) {
    controller.setProperties({
      model: model,
      enabled: this._enabled,
      stats: this._stats
    });
  }
});
