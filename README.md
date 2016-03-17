# discourse-nntp-bridge
NNTP bridge to keep NNTP &amp; Discourse in sync

Primarily used for keeping [CSH Discourse](https://discourse.csh.rit.edu) in sync with the CSH news server.

## Installation

1. Add `https://github.com/sman591/discourse-nntp-bridge.git` [as a plugin](https://meta.discourse.org/t/install-a-plugin/19157)
2. Enter the app via `./launcher enter web`
3. Run `rake discourse_nntp_bridge:assign_newsgroups` to assign newsgroups to your already-created categories

## NNTP Communication

Most of the NNTP communication was written by Alex Grant for [CSH WebNews](https://github.com/grantovich/CSH-WebNews), and is used heavily throughout this plugin.
