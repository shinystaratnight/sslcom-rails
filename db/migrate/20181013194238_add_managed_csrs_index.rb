class AddManagedCsrsIndex < ActiveRecord::Migration
  def change
    add_index :csrs, [:ssl_account_id]
  end
end
