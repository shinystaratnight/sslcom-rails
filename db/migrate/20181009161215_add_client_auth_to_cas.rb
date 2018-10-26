class AddClientAuthToCas < ActiveRecord::Migration
  def change
    add_column :cas, :client_cert, :string
    add_column :cas, :client_key, :string
    add_column :cas, :client_password, :string

  end
end
