class CreateDuoAccounts < ActiveRecord::Migration
  def self.up
    create_table :duo_accounts do |t|
      t.references  :ssl_account
      t.string      :duo_ikey, :duo_skey, :duo_akey, :duo_hostname
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :duo_accounts
  end
end
