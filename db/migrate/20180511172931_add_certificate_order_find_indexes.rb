class AddCertificateOrderFindIndexes < ActiveRecord::Migration
  def change
    add_index :certificate_orders, [:id,:ssl_account_id,:workflow_state,:is_test,:updated_at],
              unique: true, :name => 'index_certificate_orders_on_5_cols'
    add_index :certificate_contents, [:id,:certificate_order_id],
              unique: true
    add_index :csrs, [:id,:common_name,:email,:sig_alg], unique: true
    add_index :users, [:id,:status,:login,:email], unique: true
    add_index :ssl_account_users, [:id,:ssl_account_id,:user_id], unique: true
    add_index :ssl_accounts, [:id,:acct_number,:company_name,:ssl_slug], unique: true, :name => 'my_index'
  end
end
