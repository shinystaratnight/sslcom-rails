web: rails s puma -b 'ssl://0.0.0.0:3000?key=config/cert/key.pem&cert=config/cert/cert.pem' --environment=development
bullet: tail -f log/bullet.log
debug: tail -f log/development.log
worker1: bundle exec rake jobs:work
worker2: bundle exec rake jobs:work
worker3: bundle exec rake jobs:work
