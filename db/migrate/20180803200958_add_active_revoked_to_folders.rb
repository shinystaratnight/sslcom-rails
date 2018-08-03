class AddActiveRevokedToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :active, :boolean, default: false
    add_column :folders, :revoked, :boolean, default: false
  end
end
