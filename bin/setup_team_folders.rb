#!/usr/bin/env ruby
# 
# rails r bin/setup_team_folders.rb
# 
# Setup 'archive' folder and 'default' folder for every team.
#   Move expired certificte orders to archive folder.
#   Move other certificte orders to default folder.
#
SslAccount.all.each do |team|
  archive_folder = Folder.find_or_create_by(
    name: 'archive', archive: true, ssl_account_id: team.id
  )
  default_folder = Folder.find_or_create_by(
    name: 'default', default: true, ssl_account_id: team.id
  )
  
  if archive_folder.persisted? && default_folder.persisted?
    team.update(default_folder_id: default_folder.id)
    cos = team.certificate_orders
    
    expired_cos = cos.where(is_expired: true)
    expired_cos.update_all(folder_id: archive_folder.id) if expired_cos.any?
    
    default_cos = cos.where(is_expired: false)
    default_cos.update_all(folder_id: default_folder.id) if default_cos.any?
  end
end