# discourse-nntp-bridge [![Build Status](https://travis-ci.org/sman591/discourse-nntp-bridge.svg?branch=master)](https://travis-ci.org/sman591/discourse-nntp-bridge) [![Code Climate](https://codeclimate.com/github/sman591/discourse-nntp-bridge/badges/gpa.svg)](https://codeclimate.com/github/sman591/discourse-nntp-bridge) [![security](https://hakiri.io/github/sman591/discourse-nntp-bridge/master.svg)](https://hakiri.io/github/sman591/discourse-nntp-bridge/master)
NNTP bridge to keep NNTP &amp; Discourse in sync

Primarily used for keeping [CSH Discourse](https://discourse.csh.rit.edu) in sync with the CSH news server.

## Installation

1. Add `https://github.com/sman591/discourse-nntp-bridge.git` [as a plugin](https://meta.discourse.org/t/install-a-plugin/19157)
2. Add `NEWS_HOST`, `NEWS_USERNAME`, and `NEWS_PASSWORD` environment variables to your `app.yml`
3. Rebuild your app: `./launcher rebuild app`
4. Enter the app: `./launcher enter app`
5. Run `rake discourse_nntp_bridge:assign_newsgroups` to assign newsgroups to your already-created categories

### control.cancel

To sync NNTP message cancellations -> Discourse, add a Discourse category and then assign `control.cancel` to it with Step 5. If you don't want users to see this category on Discourse, you can change the category settings to be only visible to staff.

Upon a cancellation, the Discourse post won't actually be deleted - it'll be soft-deleted just like an admin "deleting" any other Discourse post, and can be recovered if needed.

Coming soon: Discourse post deletion will automatically send a control.cancel to NNTP.

Coming soon: Discourse post recovery will recover on NNTP.

## NNTP Communication

The only required environment variable is `NEWS_HOST`. `NEWS_USERNAME` and `NEWS_PASSWORD` are both optional, and at least one of the two must be present in order to send authentication along with NNTP.

Most of the NNTP communication was written by Alex Grant for [CSH WebNews](https://github.com/grantovich/CSH-WebNews), and is used/adapted upon heavily throughout this plugin.
