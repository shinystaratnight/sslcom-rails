#!/bin/bash
set -e

echo "STEP 1 of 10 => Creating Docker Network: devstack-services"

docker network create devstack-services

echo "STEP 2 of 10 => Building Docker Containers"

docker-compose build

echo "STEP 3 of 10 => Starting MySQL Service"

docker-compose start mysql

echo "STEP 4 of 10 => Application - Bundle Install"

docker-compose run --rm application bundle install

echo "STEP 5 of 10 => Application - Yarn Install"

docker-compose run --rm application yarn install

echo "STEP 6 of 10 => Application - Engine Yarn Install"

docker-compose run --rm application rake pillar_theme:webpacker:yarn_install

echo "STEP 7 of 10 => Application - Creating Database"

docker-compose run --rm application rake db:create

echo "STEP 8 of 10 => Application - Creating Database Structure"

docker-compose run --rm application rake db:structure:load

echo "STEP 9 of 10 => Application - Migrating Database"

docker-compose run --rm application rake db:migrate

echo "STEP 10 of 10 => Application - Seeding Database"

docker-compose run --rm application rake db:seed

echo "Installation Complete: Please run "
echo "docker-compose up"