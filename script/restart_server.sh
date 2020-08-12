cd /srv/www/ra/sslcom-rails
touch tmp/restart.txt

RAILS_ENV=qa bin/delayed_job -n5 restart