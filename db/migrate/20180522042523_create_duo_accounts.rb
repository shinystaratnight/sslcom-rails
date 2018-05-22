class CreateDuoAccounts < ActiveRecord::Migration
  def change
    create_table :duo_accounts do |t|
      t.references  :ssl_account
      t.string      :duo_ikey, :duo_skey, :duo_akey, :duo_hostname, :encrypted_duo_ikey, :encrypted_duo_skey, :encrypted_duo_akey, :encrypted_duo_hostname, :encrypted_duo_accounts_salt, :encrypted_duo_accounts_iv
      t.timestamps  null: false
    end
  end
end
