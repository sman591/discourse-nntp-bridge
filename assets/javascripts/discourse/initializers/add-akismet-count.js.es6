import { addFlagProperty } from 'discourse/controllers/header';

export default {
  name: 'add-akismet-count',
  before: 'register-discourse-location',
  after: 'inject-objects',

  initialize(container) {
    const user = container.lookup('current-user:main');

    if (user && user.get('staff')) {
      addFlagProperty('currentUser.akismet_review_count');

      const messageBus = container.lookup('message-bus:main');
      messageBus.subscribe("/akismet_counts", function(result) {
        if (result) {
          user.set('akismet_review_count', result.akismet_review_count || 0);
        }
      });
    }
  }
};
