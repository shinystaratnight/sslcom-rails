RailsConfig.setup do |config|
  config.const_name = "Settings"
end
# RailsConfig.load_and_set_settings("/config/client/certassure")
if DEPLOYMENT_CLIENT=~/certassure/i
  RailsConfig.load_and_set_settings(Rails.root.join("config","client","certassure", "settings.yml"))
  Settings.reload_from_files(Rails.root.join("config","client","certassure", "settings.yml"))
end
