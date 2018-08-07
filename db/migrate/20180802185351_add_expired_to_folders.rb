class AddExpiredToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :expired, :boolean, default: false
    rename_column :folders, :archive, :archived
  end
end
