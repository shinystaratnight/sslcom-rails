# set :rvm_ruby_string, '2.3.3-p222'                     # Or:
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") # Read from local system

# Load RVM's capistrano plugin.

set :rails_env, ENV['rails_env'] || ENV['RAILS_ENV'] || 'production'

# Set it to the ruby + gemset of your app, e.g 'jruby-1.5.2':
set :rvm_ruby_string, 'default'
set :rvm_type, :user

#tell git to clone only the latest revision and not the whole repository
set :git_shallow_clone, 1

set :keep_releases, 5

# Bundler
require "bundler/capistrano"
set :bundle_flags, "--deployment"
set :bundle_cmd, 'ruby -S bundle'

# Delayed Job
require 'delayed/recipes'


# Options necessary to make Ubuntu’s SSH happy
ssh_options[:paranoid] = false
default_run_options[:pty] = true

set :application, "ssl_com"
set :domain, '172.16.1.12' #Rails 4 staging
set :user, "ubuntu"
set :branch, "master"
# NOTE: for some reason Capistrano requires you to have both the public and
# the private key in the same folder, the public key should have the
# extension ".pub".
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_2019")]

server = "sandbox"
case server
  when "sandbox"
    require "rvm/capistrano"
    set :deploy_to, "/home/ubuntu/sites/#{application}"
  when "sandbox2"
    require "rvm/capistrano"
    set :application, 'ssl_com_test'
    set :deploy_to, "/home/ubuntu/sites/#{application}"
  when "sandbox3"
    require "rvm/capistrano"
    set :application, 'sandbox3_ssl_com'
    set :branch, application
    set :deploy_to, "/home/ubuntu/sites/ssl_com_test"
  when "sandbox4"
    require "rvm/capistrano"
    set :application, 'sandbox4_ssl_com'
    set :branch, application
    set :deploy_to, "/home/ubuntu/sites/ssl_com_test"
  when "staging"
    require "rvm/capistrano"
    set :deploy_to, "/home/ubuntu/sites/#{application}"
  when "production"
    require "rvm/capistrano"
    set :branch, "master"
    set :domain, 'ra.sslpki.local'
    set :deploy_to, "/home/ubuntu/sites/#{application}"
    ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "sws-a1.sslpki.local.key")]
  when "production_api"
    set :application, "sws"
    set :user, "app-sws"
    set :branch, "master"
    set :domain, 'sws-a1.sslpki.local'
    set :deploy_to, "/srv/www/#{application}"
    ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "sws-a1.sslpki.local.key")]
end

#set :deploy_via, :copy
#set :copy_strategy, :export
#set :copy_remote_dir, "/tmp"
#set :copy_compression, :zip

# Alternate SCM
# Git
set :scm, :git
set :repository, "git@github.com:SSLcom/sslcom-rails.git"
set :deploy_via, :remote_cache
set :ssh_options, {:forward_agent => true}

set :use_sudo, false

role :cache, domain
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

namespace :memcached do
  desc "Flushes memcached local instance"
  task :flush, :roles => [:app] do
    run("cd #{current_path} && bundle exec rake memcached:flush")
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

# after 'deploy:update_code', 'bundler:bundle_new_release'
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"
after "deploy:restart", "deploy:cleanup"

namespace :delayed_job do
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path} && #{rails_env} bin/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path} && #{rails_env} bin/delayed_job -n 5 start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path} && #{rails_env} bin/delayed_job -n 5 restart"
  end
end

desc 'remote rails console'
@object = namespace :rails do
  task :console, :roles => :app do
    exec %{ssh -l #{user} #{domain} -t "~/.rvm/script/rvm-shell -c 'cd #{current_path} && bundle exec rails c #{rails_env}'"}
  end
end
@object

namespace :deploy do
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/settings.yml #{release_path}/config/settings.yml"
    run "ln -nfs #{shared_path}/config/initializers/session_store.rb #{release_path}/config/initializers/session_store.rb"
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
    #preserve backwards compatibility
    run "ln -nfs #{shared_path}/images #{release_path}/public/images"
    run "ln -nfs #{shared_path}/javascripts #{release_path}/public/javascripts"
    run "ln -nfs #{shared_path}/stylesheets #{release_path}/public/stylesheets"
    run "ln -nfs #{shared_path}/repository #{release_path}/public/repository"
    run "ln -nfs #{shared_path}/repository #{release_path}/public/certs"
    run "ln -nfs #{shared_path}/config/local_env.yml #{release_path}/config/local_env.yml"
    run "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
    run "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
    run "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run "ln -nfs #{shared_path}/config/cert/ejbca_api/* #{release_path}/config/cert/ejbca_api/"
  end

end
after 'deploy:update', 'deploy:symlink_shared'
after 'deploy:publishing', 'deploy:restart'

#auto install rvm
#before 'deploy', 'rvm:install_rvm'


#whenever
# set :whenever_command, "bundle exec whenever"
# disable this on production web
#require "whenever/capistrano"

#whenever
# set :whenever_command, "bundle exec whenever"
# disable this on production web
#require "whenever/capistrano"
