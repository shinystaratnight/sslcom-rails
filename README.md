# SSL.com Rails

## Getting set up

1. Import the VirtualBox image into VirtualBox
2. Set `www.ssl.local` to `127.0.0.1` in /etc/hosts (OS X) or hosts file on Win32. Make sure you flush your DNS.
3. Clone the SSL.com Rails Repo
4. Create `.vagrant/machines/default/virtualbox/creator_uid` put your machine user's UID. For Macs it's usually 501, Windows 0.
5. Create `.vagrant/machines/default/virtualbox/synced_folders` and edit the hostpath to match the directory of the cloned Rails repo. Template is available below.
6. Start the Vagrant machine `vagrant up`
7. SSH into the box `vagrant ssh`
8. Navigate to `/vagrant` and run `./start-local`
9. Navigate to `https://www.ssl.local:3000/` in your browser and it should work!

### `synced_folders` Template
```
{"virtualbox":{"/vagrant":{"guestpath":"/vagrant","hostpath":"INSERT_PATH_HERE","disabled":false,"__vagrantfile":true}}}
```

## Migrating to SSL.com v3.0
`rails runner bin/populate_multitenant_tables.rb -e production`

## Migrating to multi-team
`rails runner bin/populate_roles_team_update.rb -e production`
