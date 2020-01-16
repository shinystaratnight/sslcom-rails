web: rails s webrick -b 0.0.0.0 --environment=development
bullet: tail -f log/bullet.log
debug: tail -f log/development.log
worker1: bundle exec rake jobs:work
worker2: bundle exec rake jobs:work
worker3: bundle exec rake jobs:work
