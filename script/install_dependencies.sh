##!/bin/bash

cd /srv/www/ra/

cp ./config/*.yml ./sslcom-rails/config/.
cd sslcom-rails
PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"
bundle install --deployment
RAILS_ENV=qa rake db:migrate
yarn install
RAILS_ENV=qa WEBPACKER_PRECOMPILE=false rake assets:precompile
RAILS_ENV=qa bundle exec rake --trace pillar_theme:webpacker:compile
