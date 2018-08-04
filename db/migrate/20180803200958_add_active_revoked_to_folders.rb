class AddActiveRevokedToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :active, :boolean, default: false
    add_column :folders, :revoked, :boolean, default: false

    add_column :signed_certificates, :revoked_at, :datetime
  end
end
