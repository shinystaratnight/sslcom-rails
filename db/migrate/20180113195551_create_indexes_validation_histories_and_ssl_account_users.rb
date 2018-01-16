class CreateIndexesValidationHistoriesAndSslAccountUsers < ActiveRecord::Migration
  def change
    add_index :validation_histories, :validation_id
    add_index :ssl_account_users, [:user_id, :ssl_account_id, :approved, :user_enabled], name: "index_ssl_account_users_on_four_fields"
    add_index :assignments, [:user_id,:ssl_account_id]
    add_index :orders, [:state,:billable_id,:billable_type]
  end
end
