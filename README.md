# SSL.com Rails

[![CircleCI](https://circleci.com/gh/SSLcom/sslcom-rails/tree/master.svg?style=svg&circle-token=6c2cc58a545d1d674d5e8f97809671be9fe38a2a)](https://circleci.com/gh/SSLcom/sslcom-rails/tree/master)

[![Maintainability](https://api.codeclimate.com/v1/badges/a8f3ee62506a9befd80a/maintainability)](https://codeclimate.com/repos/5e18e6aa249421017701af15/maintainability)

[![Test Coverage](https://api.codeclimate.com/v1/badges/a8f3ee62506a9befd80a/test_coverage)](https://codeclimate.com/repos/5e18e6aa249421017701af15/test_coverage)


## Getting Started

1. Get access to SSL.com's VPN (Ask Leo or developers).

2. Download and install Docker Desktop for your platform
    
    ( https://www.docker.com/products/docker-desktop )

## Application Setup - Docker

1. Set the following in /etc/hosts (OS X) or hosts file on Win32. Make sure you flush your DNS.
    - `secure.ssl.local` to `127.0.0.1`
    - `sws-test.sslpki.local` to `127.0.0.1`
    - `sws.sslpki.local` to `127.0.0.1`
    - `sandbox.ssl.local` to `127.0.0.1`
    - `reseller.ssl.local` to `127.0.0.1`

2. Clone the SSL.com Rails Repo

3. Download and place `database.yml`, `secrets.yml`, `local_env.yml` and `settings.yml` into the config directory.

    Contact a developer to get these files.

4. Run the command: `docker network create devstack-services`

5. Run the command: `docker-compose build`

6. Run the command: `docker-compose up  -d mysql`

7. Run the command: `docker-compose up  -d application`

8. Run the command: `docker-compose run --rm application bundle install`

9. Run the command: `docker-compose run --rm application yarn install`

10. Run the command: `docker-compose run --rm application rake pillar_theme:webpacker:yarn_install`

11. Run the command: `docker-compose run --rm application rake db:create`

12. Run the command: `docker-compose run --rm application rake db:structure:load`

13. Run the command: `docker-compose run --rm application rake db:migrate`

14. Run the command: `docker-compose run --rm application rake db:seed`

15. Run the command: `docker-compose run --rm application rake cas:seed_ejbca_profiles LIVE=all EJBCA_ENV=development RAILS_ENV=development`

16. Run the command: `docker-compose restart application`

17. Navigate to `https://secure.ssl.local:3000/` in your browser and it should work!

#### NOTES:

To start Rails Console:

`docker-compose run --rm application rails c`

To get into the Application Command Line:

`docker-compose run --rm application zsh`

##### For additional help on Docker please visit or contact a developer:

https://sslcom.atlassian.net/l/c/69S14q2r



#

## Application Setup - Vagrant (DEPRECIATED)

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
8. SSH into the vagrant environment `vagrant ssh`, navigate to the SSL.com repo and run `yarn` then `bundle install`.
9. Download and place database.yml, secrets.yml, local_env.yml, and settings.yml into the config directory.
10. Setup Pillar by running the following commands `pillar_theme:webpacker:yarn_install`
11. Create the development database with `RAILS_ENV=development rake db:create`. If prompted for a password, type `vagrant`.
12. Get the schema by typing `RAILS_ENV=development rake db:structure:load`
13. Run any needed migrations `RAILS_ENV=development rake db:migrate`.
14. Download sandbox_ssl_com.sql and populate the database with `mysql -u ssl_db -p sandbox_ssl_com < database_ssl_com.sql`
15. Run migrations again `bundle exec rake db:migrate RAILS_ENV=development`
16. Execute the following command: LIVE=all EJBCA_ENV=development RAILS_ENV=development bundle exec rake cas:seed_ejbca_profiles
17. Navigate to the repo and run `foreman start web`
18. Navigate to `https://secure.ssl.local:3000/` in your browser and it should work!
19. Get access to SSL.com's VPN (Ask Leo or developers).

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

