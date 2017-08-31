# discourse-nntp-bridge [![Build Status](https://travis-ci.org/sman591/discourse-nntp-bridge.svg?branch=master)](https://travis-ci.org/sman591/discourse-nntp-bridge) [![Code Climate](https://codeclimate.com/github/sman591/discourse-nntp-bridge/badges/gpa.svg)](https://codeclimate.com/github/sman591/discourse-nntp-bridge) [![security](https://hakiri.io/github/sman591/discourse-nntp-bridge/master.svg)](https://hakiri.io/github/sman591/discourse-nntp-bridge/master)
NNTP bridge to keep NNTP &amp; Discourse in sync

Primarily used for keeping [CSH Discourse](https://discourse.csh.rit.edu) in sync with the CSH news server.

## Installation

1. Add `https://github.com/sman591/discourse-nntp-bridge.git` [as a plugin](https://meta.discourse.org/t/install-a-plugin/19157)
2. Add `NEWS_HOST`, `NEWS_USERNAME`, and `NEWS_PASSWORD` environment variables to your `app.yml`
3. Rebuild your app: `./launcher rebuild app`
4. Enter the app: `./launcher enter app`
5. Run `rake discourse_nntp_bridge:assign_newsgroups` to assign newsgroups to your already-created categories

## NNTP Communication

The only required environment variable is `NEWS_HOST`. `NEWS_USERNAME` and `NEWS_PASSWORD` are both optional, and at least one of the two must be present in order to send authentication along with NNTP.

Most of the NNTP communication was written by Alex Grant for [CSH WebNews](https://github.com/grantovich/CSH-WebNews), and is used/adapted upon heavily throughout this plugin.

## Development

Development requires running a local copy of the latest-release of Discourse.

Assuming you store repositories in `~/dev`, the Discourse repo should be located at `~/dev/discourse` and the NNTP bridge repo should be at `~/dev/discourse-nntp-bridge`.

```bash
cd ~/dev/
git clone git@github.com:discourse/discourse.git
cd discourse
git fetch --tags
git checkout tags/latest-release
cd plugins && ln -s ../../discourse-nntp-bridge && cd ../
```

This clones Discourse, checks out the `latest-release` tag, and adds `discourse-nntp-bridge` to the plugin directory via a symlink --- making it easy to make changes to the plugin in development.

After this, you'll want to get Discourse set up & running locally. See [Discourse's README](https://github.com/discourse/discourse/blob/latest-release/README.md#development) for more info!
