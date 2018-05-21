class AddToDuoAccounts < ActiveRecord::Migration
  def self.up
    change_table :duo_accounts do |t|
      t.string :encrypted_duo_ikey_salt
      t.string :encrypted_duo_ikey_iv
      t.string :encrypted_duo_skey_salt
      t.string :encrypted_duo_skey_iv
      t.string :encrypted_duo_akey_salt
      t.string :encrypted_duo_akey_iv
      t.string :encrypted_duo_hostname_salt
      t.string :encrypted_duo_hostname_iv    
    end
  end

  def self.down
    change_table :billing_profiles do |t|
      t.remove :encrypted_duo_ikey_salt, :encrypted_duo_ikey_iv, :encrypted_duo_skey_salt, :encrypted_duo_skey_iv, :encrypted_duo_akey_salt, :encrypted_duo_akey_iv, :encrypted_duo_hostname_salt, :encrypted_duo_hostname_iv
    end
  end
end
