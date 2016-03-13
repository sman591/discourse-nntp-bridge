export default {
  name: 'rewrite-plugin-outlets',

  initialize() {
    // TODO: Once `rewire` is in stable replace this with a regular `import`
    const outletModule = require('discourse/helpers/plugin-outlet');
    if (outletModule && outletModule.rewire) {
      outletModule.rewire('akismet-review', 'site-map-links', 'hamburger-admin');
    }
  }
}
