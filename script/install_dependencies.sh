#!/bin/bash
cd /home/ubuntu/sslcom-rails
sudo chown ubuntu:ubuntu -R .
cp ../*.yml /home/ubuntu/sslcom-rails/config/.
RAILS_ENV=production bundle install
RAILS_ENV=production bundle exec rake assets:precompile
