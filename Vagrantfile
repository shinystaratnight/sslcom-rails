# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.network "forwarded_port", guest: 80,    host: 80,    auto_correct: true
  config.vm.network "forwarded_port", guest: 443,   host: 443,   auto_correct: true
  config.vm.network "forwarded_port", guest: 1234,  host: 61234, auto_correct: true
  config.vm.network "forwarded_port", guest: 3000,  host: 3000,  auto_correct: true
  config.vm.network "forwarded_port", guest: 4443,  host: 4443,  auto_correct: true
  config.vm.network "forwarded_port", guest: 9515,  host: 9515,  auto_correct: true
  config.vm.network "forwarded_port", guest: 10000, host: 10000, auto_correct: true

  # Always upgrade to latest packages
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    apt-get update
    apt-get -y upgrade
  SHELL

  # # Install Ruby2.6 from Brightbox APT repository
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get -y install software-properties-common
  #   apt-add-repository -y ppa:brightbox/ruby-ng
  #   apt-get update
  #   apt-get -y install ruby-switch ruby-bundler ruby2.6 ruby2.6-dev
  # SHELL
  #
  # # Install Passenger + Nginx through Phusion's APT repository
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get install -y dirmngr gnupg
  #   apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
  #   echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main" > /etc/apt/sources.list.d/passenger.list
  #   apt-get update
  #   apt-get install -y nginx-extras passenger
  # SHELL
  #
  # ##
  # ## Additional services that are not needed but may help in managing the server.
  # ## Note that for webmin specifically, a port needs to be forwarded for it to work.
  # ##
  # ## WEBMIN
  # ## ref.: https://doxfer.webmin.com/Webmin/Installation#apt-get_.28Debian.2FUbuntu.2FMint.29
  # ## IMPORTANT: Make sure wget is being installed above. Credentials for webmin should be vagrant/vagrant.
  # ##
  # config.vm.provision "shell", inline: <<-SHELL
  #   echo -e "\n --> Installing Webmin.\n\n"
  #   sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
  #   wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
  #   apt-get update
  #   apt-get install -y webmin >/dev/null 2>&1
  #   apt-get -y install memcached
  # SHELL
  #
end