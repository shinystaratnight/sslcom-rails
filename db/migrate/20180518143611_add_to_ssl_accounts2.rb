class AddToSslAccounts2 < ActiveRecord::Migration
  def self.up
    change_table :ssl_accounts do |t|
      t.boolean :duo_own_used
    end
  end

  def self.down
    change_table :ssl_accounts do |t|
      t.remove :duo_own_used
    end
  end
end
