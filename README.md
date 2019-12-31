# SSL.com Rails

## Getting set up

1. Download VirtualBox and import the image into VirtualBox.
2. Set the following in /etc/hosts (OS X) or hosts file on Win32. Make sure you flush your DNS.
  a. `secure.ssl.local` to `127.0.0.1`
  b. `sws-test.sslpki.local` to `127.0.0.1`
  c. `sws.sslpki.local` to `127.0.0.1`
  d. `sandbox.ssl.local` to `127.0.0.1`
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
13. Download sandbox_ssl_com.sql and populate the database with `mysql -u ssl_db -p sandbox_ssl_com < sandbox_ssl_com.sql`
14. Navigate to the repo and run `./start-dev`
15. Navigate to `https://secure.ssl.local:3000/` in your browser and it should work!

### Run Delayed Job

1. In another tab, SSH into the box `vagrant ssh`
2. Navigate to `/vagrant` and run `rake jobs:work`
3. To terminate delayed job server, press `Ctr+C`

### `synced_folders` Template

```
{"virtualbox":{"/vagrant":{"guestpath":"/vagrant","hostpath":"INSERT_PATH_HERE","disabled":false,"__vagrantfile":true}}}
```
