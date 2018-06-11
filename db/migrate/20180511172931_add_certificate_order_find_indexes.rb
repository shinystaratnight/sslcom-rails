class AddCertificateOrderFindIndexes < ActiveRecord::Migration
  def change
    add_index :certificate_orders, [:ssl_account_id,:workflow_state,:is_test,:updated_at],
              :name => 'index_certificate_orders_on_4_cols'
    add_index :certificate_orders, [:workflow_state,:is_expired,:is_test],
              :name => 'index_certificate_orders_on_3_cols'
    add_index :csrs, [:common_name,:email,:sig_alg]
    add_index :users, [:status,:login,:email]
  end
end
