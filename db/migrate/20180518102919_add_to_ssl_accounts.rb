class AddToSslAccounts < ActiveRecord::Migration
  def self.up
    change_table :ssl_accounts do |t|
      t.boolean :duo_enabled
    end
  end

  def self.down
    change_table :ssl_accounts do |t|
      t.remove :duo_enabled
    end
  end
end
