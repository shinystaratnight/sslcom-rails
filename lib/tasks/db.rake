if Rails.env == 'production'
  tasks = Rake.application.instance_variable_get '@tasks'
  tasks.delete 'db:reset'
  tasks.delete 'db:drop'
  namespace :db do
    desc 'db:reset not available in this environment'
    task :reset do
      puts 'db:reset has been disabled'
    end
    desc 'db:drop not available in this environment'
    task :drop do
      puts 'db:drop has been disabled'
    end
  end
end

namespace :db do
  namespace :test do
    desc 'Clean before running database for test'
    task clear: :environment do
      if Rails.env == 'test'
        # User.destroy_all
        User.connection.truncate(User.table_name)
        puts 'Database has been cleared for tests'
      end
    end
  end
end
