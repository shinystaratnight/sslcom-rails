class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index :preferences, [:group_id,:group_type,:owner_id,:owner_type,:value],
              :name => 'index_preferences_on_5_cols'
    add_index :preferences, [:owner_type,:owner_id]
    add_index :sub_order_items, [:sub_itemable_id,:sub_itemable_type]
    add_index :csrs, [:common_name,:email,:sig_alg],
              :name => 'index_csrs_on_3_cols'
    add_index :signed_certificates, [:common_name,:strength],
              :name => 'index_signed_certificates_on_3_cols'
    add_index :api_credentials, [:ssl_account_id]
  end
end
