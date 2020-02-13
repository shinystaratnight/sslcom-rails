web: rails s puma -b 'ssl://0.0.0.0:3000?key=config/cert/key.pem&cert=config/cert/cert.pem' --environment=development
bullet: tail -f log/bullet.log
delayed_job: bundle exec rake jobs:work -m process=3
