# Ensure RVM gems are loaded
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.
require "rvm/capistrano"

set :rails_env, ENV['rails_env'] || ENV['RAILS_ENV'] || 'production'

# Set it to the ruby + gemset of your app, e.g 'jruby-1.5.2':
set :rvm_ruby_string, 'default'
set :rvm_type, :user

#tell git to clone only the latest revision and not the whole repository
set :git_shallow_clone, 1

set :keep_releases, 3

# Bundler
require 'bundler/capistrano'
set :bundle_flags, "--deployment"
set :bundle_cmd, 'ruby -S bundle'

# Options necessary to make Ubuntu’s SSH happy
ssh_options[:paranoid] = false
default_run_options[:pty] = true

set :application, "ssl_com"
set :domain, 'staging2.ssl.com'
#set :deploy_via, :copy
#set :copy_strategy, :export
#set :copy_remote_dir, "/tmp"
#set :copy_compression, :zip

# Alternate SCM
# Git
set :scm, :git
set :repository, "git@github.com:codelux/ssl.git"
set :deploy_to, "/home/ubuntu/sites/#{application}"
set :deploy_via, :remote_cache

# NOTE: for some reason Capistrano requires you to have both the public and
# the private key in the same folder, the public key should have the
# extension ".pub".
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]

set :user, "ubuntu"
set :branch, "master"
set :use_sudo, false

role :web, domain # Your HTTP server, Apache/etc
role :app, domain # This may be the same as your `Web` server
role :db, domain, :primary => true # This is where Rails migrations will run
# role :db, "your slave db-server here"

#need to override to talk to passenger and passenger only knows restart
  namespace :passenger do

    desc <<-DESC
      Restarts your application. \
      This works by creating an empty `restart.txt` file in the `tmp` folder
      as requested by Passenger server.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end

    desc <<-DESC
      Starts the application servers. \
      Please note that this task is not supported by Passenger server.
    DESC
    task :start, :roles => :app do
      logger.info ":start task not supported by Passenger server"
    end

    desc <<-DESC
      Stops the application servers. \
      Please note that this task is not supported by Passenger server.
    DESC
    task :stop, :roles => :app do
      logger.info ":stop task not supported by Passenger server"
    end

  end

  namespace :deploy do

    desc <<-DESC
      Restarts your application. \
      Overwrites default :restart task for Passenger server.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      passenger.restart
    end

    desc <<-DESC
      Starts the application servers. \
      Overwrites default :start task for Passenger server.
    DESC
    task :start, :roles => :app do
      passenger.start
    end

    desc <<-DESC
      Stops the application servers. \
      Overwrites default :start task for Passenger server.
    DESC
    task :stop, :roles => :app do
      passenger.stop
    end

  end

# bundler
namespace :bundler do
  task :install do
    run("gem install bundler --source=http://gemcutter.org")
  end

  task :symlink_vendor do
  shared_gems = File.join(shared_path, 'vendor/bundler_gems')
  release_gems = "#{release_path}/vendor/bundler_gems/"
    %w(cache gems specifications).each do |sub_dir|
      shared_sub_dir = File.join(shared_gems, sub_dir)
      run("mkdir -p #{shared_sub_dir} && mkdir -p #{release_gems} && ln -s #{shared_sub_dir} #{release_gems}/#{sub_dir}")
    end
  end

  task :bundle_new_release do
    bundler.symlink_vendor
    run("cd #{release_path} && bundle --only #{rails_env}")
  end
end

#after 'deploy:update_code', 'bundler:bundle_new_release'
#after "deploy:stop",    "delayed_job:stop"
#after "deploy:start",   "delayed_job:start"
#after "deploy:restart", "delayed_job:restart"
#after "deploy", "delayed_job:restart"
namespace :delayed_job do
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job -n 5 start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job -n 5 restart"
  end
end

desc "remotely console"
 task :console, :roles => :app do
   input = ''
   run "cd #{current_path} && ./script/console #{rails_env}", :once => true do |channel, stream, data|
     next if data.chomp == input.chomp || data.chomp == ''
     print data
     channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
   end
 end

namespace :deploy do
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end
after 'deploy:update', 'deploy:symlink_shared'