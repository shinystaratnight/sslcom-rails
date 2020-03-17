require 'find'

namespace :db do
  desc "export the database models to YML fixtures (for specific models use MODELS=User,Post, etc)"
  task(:models_to_fixtures => :environment) do
    ActiveRecord::Base.establish_connection("development")
    ActiveRecord::Base.connection

    models = []
    if ENV['MODELS'].nil? || ENV['MODELS'].blank?
      raise "Please enter valid models names separated by coma. Ex: MODELS=User,Account or MODELS=ALL"
    elsif ENV['MODELS'].upcase == "ALL"
      Find.find(Rails.root + '/app/models') do |path|
        unless File.directory?(path) then models << path.match(/(\w+).rb/)[1] end
      end
      models = models.collect { |arg| arg.strip.camelize.constantize }
    else
      models = ENV['MODELS'].split(',').collect { |arg| arg.strip.camelize.constantize }
    end

    models.each do |model|
      output = {}
      collection = []
      if model.respond_to? :is_live? #hack for models that use acts_as_publishable
        collection = Release.find_by_sql("SELECT * From #{model.table_name} WHERE id > 0")
      elsif model.respond_to? :table_name
        begin
          collection = model.find(:all)
        rescue
          next
        end
      end
      unless collection.blank?
        collection.each do |object|
          output.store(object.to_param, object.attributes)
        end
        file_path = "#{Rails.root}/tmp/#{model.table_name}.yml" # /tmp/
        File.open(file_path, "w+") { |file| file.write(output.to_yaml) }
      end
    end
  end
end
