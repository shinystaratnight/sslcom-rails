class AddStatusToSslAccount < ActiveRecord::Migration
  def self.up
    add_column :ssl_accounts, :status, :string
  end

  def self.down
    remove_column :ssl_accounts, :status
  end
end
