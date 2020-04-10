# SSL.com Rails

[![CircleCI](https://circleci.com/gh/SSLcom/sslcom-rails/tree/master.svg?style=svg&circle-token=6c2cc58a545d1d674d5e8f97809671be9fe38a2a)](https://circleci.com/gh/SSLcom/sslcom-rails/tree/master)

[![Maintainability](https://api.codeclimate.com/v1/badges/a8f3ee62506a9befd80a/maintainability)](https://codeclimate.com/repos/5e18e6aa249421017701af15/maintainability)

[![Test Coverage](https://api.codeclimate.com/v1/badges/a8f3ee62506a9befd80a/test_coverage)](https://codeclimate.com/repos/5e18e6aa249421017701af15/test_coverage)

## Getting set up

1. Download VirtualBox and import the image into VirtualBox.
2. Set the following in /etc/hosts (OS X) or hosts file on Win32. Make sure you flush your DNS.
  a. `secure.ssl.local` to `127.0.0.1`
  b. `sws-test.sslpki.local` to `127.0.0.1`
  c. `sws.sslpki.local` to `127.0.0.1`
  d. `sandbox.ssl.local` to `127.0.0.1`
  e. `reseller.ssl.local` to `127.0.0.1`
3. Download Vagrant and `vagrant init` in the terminal.
4. Clone the SSL.com Rails Repo
5. Create `.vagrant/machines/default/virtualbox/creator_uid` put your machine user's UID. For Macs it's usually 501, Windows 0.
6. Create `.vagrant/machines/default/virtualbox/synced_folders` and edit the hostpath to match the directory of the cloned Rails repo. Template is available below.
7. Use the Vagrantfile in the SSL.com repository to `vagrant up` and build the environment.
8. SSH into the vagrant environment `vagrant ssh`, navigate to the SSL.com repo and `bundle install`.
9. Download and place database.yml, secrets.yml, local_env.yml, and settings.yml into the config directory.
10. Create the development database with `RAILS_ENV=development rake db:create`. If prompted for a password, type `vagrant`.
11. Get the schema by typing `RAILS_ENV=development rake db:structure:load`
12. Run any needed migrations `RAILS_ENV=development rake db:migrate`.
13. Download sandbox_ssl_com.sql and populate the database with `mysql -u ssl_db -p sandbox_ssl_com < database_ssl_com.sql`
14. Run migrations again `bundle exec rake db:migrate RAILS_ENV=development`
15. Execute the following command: LIVE=all EJBCA_ENV=development RAILS_ENV=development bundle exec rake cas:seed_ejbca_profiles
16. Navigate to the repo and run `foreman start web`
17. Navigate to `https://secure.ssl.local:3000/` in your browser and it should work!
18. Get access to SSL.com's VPN (Ask Leo or developers).

### `synced_folders` Template

```json
{"virtualbox":{"/vagrant":{"guestpath":"/vagrant","hostpath":"INSERT_PATH_HERE","disabled":false,"__vagrantfile":true}}}
```

### Note on setting up Vagrant with Rubymine

rbenv installation may be required in the vagrant instance so the Rubymine vagrant plugin get see the Ruby Interpreter
https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04

### Note on running on puma

when running puma, enable ssl like so

```bash
puma -b 'ssl://0.0.0.0:3000?key=config/cert/key.pem&cert=config/cert/cert.pem'
```
