class CreateSslAccountUsers < ActiveRecord::Migration
  def change
    drop_table :ssl_account_users
    
    create_table :ssl_account_users do |t|
      t.references :user, null: false, index: true, limit: 4
      t.references :ssl_account, null: false, index: true, limit: 4
      t.timestamps
    end
    add_index :ssl_account_users, [:ssl_account_id, :user_id]
  end
end
