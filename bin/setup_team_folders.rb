#!/usr/bin/env ruby
# 
# rails r bin/setup_team_folders.rb
# 
# Setup 'archived', 'expired' and 'default' folder for every team.
#   Move expired certificate orders to archive folder.
#   Move other certificate orders to default folder.
#
SslAccount.find_each do |team|
  archived_exist = Folder.where(name: 'archive', archived: true)
  
  if archived_exist.any?
    archived_exist.update_all(name: 'archived')
  end

  archive_folder = Folder.find_or_create_by(
    name: 'archived', archived: true, ssl_account_id: team.id
  )

  default_folder = Folder.find_or_create_by(
    name: 'default', default: true, ssl_account_id: team.id
  )
  
  expired_folder = Folder.find_or_create_by(
    name: 'expired', expired: true, ssl_account_id: team.id
  )
  
  active_folder = Folder.find_or_create_by(
    name: 'active', active: true, ssl_account_id: team.id
  )
  
  revoked_folder = Folder.find_or_create_by(
    name: 'revoked', revoked: true, ssl_account_id: team.id
  )
  
  if archive_folder.persisted? && default_folder.persisted?
    team.update(default_folder_id: default_folder.id)
    cos = team.certificate_orders
    
    # expired certificates
    expired_cos = team.certificate_orders.expired
    expired_cos.update_all(folder_id: expired_folder.id) if expired_cos.any?
    
    # revoked certificates
    revoked_cos = team.certificate_orders.revoked
    revoked_cos.update_all(folder_id: revoked_folder.id) if revoked_cos.any?

    default_cos = cos.where.not(
      id: (expired_cos.map(&:id) + revoked_cos.map(&:id)).compact.uniq.flatten
    )
    default_cos.update_all(folder_id: default_folder.id) if default_cos.any?
  end
end