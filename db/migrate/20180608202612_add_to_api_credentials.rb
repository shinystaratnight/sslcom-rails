class AddToApiCredentials < ActiveRecord::Migration
  def change
    add_column :api_credentials, :roles, :string
  end
end
