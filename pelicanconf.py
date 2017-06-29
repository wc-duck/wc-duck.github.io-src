#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Fredrik Kihlander'
SITEURL = 'http://kihlander.net'
#SITEURL = 'http://localhost:8000'
SITENAME = 'The blog of Fredrik Kihlander'
SITETITLE = 'What could possibly go wrong?'
SITESUBTITLE = 'The blog of Fredrik Kihlander'
SITEDESCRIPTION = 'Foo Bar\'s Thoughts and Writings'
SITELOGO = SITEURL + '/theme/img/profile.png'
TIMEZONE = 'Europe/Stockholm'

FAVICON = SITEURL + '/images/favicon.ico'
ROBOTS = 'index, follow'

COPYRIGHT_YEAR = 2015
CC_LICENSE = { 'name': 'Creative Commons Attribution-ShareAlike', 'version':'4.0', 'slug': 'by-sa' }

EXTRA_PATH_METADATA = {
    'extra/custom.css': {'path': 'static/custom.css'},
}
CUSTOM_CSS = 'static/custom.css'

USE_FOLDER_AS_CATEGORY = True
MAIN_MENU = True

MENUITEMS = (('Archives', '/archives.html'),
             ('Categories', '/categories.html'),
             ('Tags', '/tags.html'),)

DEFAULT_PAGINATION = 10
THEME = 'flex'

SOCIAL = (('github', 'https://github.com/wc-duck'),
          ('twitter', 'https://twitter.com/wc_duck'),
          ('rss', '/feeds/all.atom.xml')
	)

STATIC_PATHS = ['images']

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = False
