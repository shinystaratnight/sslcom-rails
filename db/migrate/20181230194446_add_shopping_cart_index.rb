class AddShoppingCartIndex < ActiveRecord::Migration
  def change
    add_index :shopping_carts, :guid
    add_index :api_credentials,[:account_key, :secret_key], :unique => true
    add_index :notification_groups_subjects,[:subjectable_id, :subjectable_type],
              name: "index_notification_groups_subjects_on_two_fields"
    add_index :folders, :archived
    add_index :folders, :expired
    add_index :folders, :active
    add_index :folders, :revoked
  end
end
