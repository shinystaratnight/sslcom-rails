class CreateOrderTransactions < ActiveRecord::Migration
  def self.up
    create_table :order_transactions do |t|
      t.references  :order
      t.integer     :amount
      t.boolean     :success
      t.string      :reference
      t.string      :message
      t.string      :action
      t.text        :params
      t.text        :avs
      t.text        :cvv
      t.string      :fraud_review
      t.boolean     :test
      t.string      :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :order_transactions
  end
end
