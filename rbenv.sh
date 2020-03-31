  #!/bin/bash

  sudo apt-get -y update
  sudo apt-get -y install curl git-core python-software-properties ruby-dev libpq-dev build-essential nginx libsqlite3-0 libsqlite3-dev libxml2 libxml2-dev libxslt1-dev libreadline-dev

  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"'               >> ~/.bashrc
  source ~/.bashrc

  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  sudo -H -u vagrant bash -i -c 'rbenv install 2.6.5'
  sudo -H -u vagrant bash -i -c 'rbenv rehash'
  sudo -H -u vagrant bash -i -c 'rbenv global 2.6.5'
  sudo -H -u vagrant bash -i -c 'gem install bundler --no-ri --no-rdoc'
  sudo -H -u vagrant bash -i -c 'rbenv rehash'
