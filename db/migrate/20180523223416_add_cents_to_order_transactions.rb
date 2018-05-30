class AddCentsToOrderTransactions < ActiveRecord::Migration
  def change
    add_column :order_transactions, :cents, :integer
    rename_column :order_transactions, :amount, :old_amount
  end
end
