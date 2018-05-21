class AddEncryptedToDuo < ActiveRecord::Migration
  def self.up
    change_table :duo_accounts do |t|
      t.string :encrypted_duo_ikey
      t.string :encrypted_duo_skey
      t.string :encrypted_duo_akey
      t.string :encrypted_duo_hostname    
    end
  end

  def self.down
    change_table :billing_profiles do |t|
      t.remove :encrypted_duo_ikey, :encrypted_duo_skey, :encrypted_duo_akey, :encrypted_duo_hostname
    end
  end
end
