##!/bin/bash

cd /srv/www/ra/

cp ./config/*.yml ./sslcom-rails/config/.
cd sslcom-rails
PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"
bundle install --deployment
RAILS_ENV=qa rake db:migrate
RAILS_ENV=qa rake assets:precompile
RAILS_ENV=qa rake assets:clean
