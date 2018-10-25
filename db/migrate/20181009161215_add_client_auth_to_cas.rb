class AddClientAuthToCas < ActiveRecord::Migration
  def change
    add_column :cas, :client_cert, :string
    add_column :cas, :client_key, :string
    add_column :cas, :client_password, :string

    add_index :csrs, [:ssl_account_id]

  end
end
