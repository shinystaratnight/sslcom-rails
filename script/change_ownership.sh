#!/bin/bash

cd /srv/www/ra/sslcom-rails

# Set ownership for all folders
chown -R app-ra:app-ra /srv/www/ra/sslcom-rails

# set files to 660
find /srv/www/ra/sslcom-rails -type f  -print0 | xargs -0 chmod 0660

# set folders to 0770
find /srv/www/ra/sslcom-rails -type d -print0 | xargs -0 chmod 0770
