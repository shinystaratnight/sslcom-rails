class AddMoreIndexes2 < ActiveRecord::Migration
  def change
    add_index :ssl_accounts, [:ssl_slug,:acct_number]
    add_index :certificate_orders, [:ssl_account_id, :workflow_state, :id],
              name: 'index_certificate_orders_on_3_cols(2)'
    add_index :certificate_orders, [:workflow_state,:is_expired,:renewal_id],
              :name => 'index_certificate_orders_on_ws_is_ri'
  end
end
