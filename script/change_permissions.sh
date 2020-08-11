#!/bin/bash
# set files to 660
find /srv/www/ra/sslcom-rails -type f  -print0 | xargs -0 chmod 0660
# set folders to 0770
find /srv/www/ra/sslcom-rails -type d -print0 | xargs -0 chmod 0770
# set execute permission to binaries
chmod u+x,g+x /srv/www/ra/sslcom-rails/bin/*