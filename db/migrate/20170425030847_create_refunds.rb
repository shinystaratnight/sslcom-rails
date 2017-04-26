class CreateRefunds < ActiveRecord::Migration
  def change
    create_table :refunds do |t|
      t.string     :merchant, required: true
      t.string     :reference
      t.integer    :amount, required: true
      t.string     :status, required: true
      t.references :user, index: true
      t.references :order, index: true, required: true
      t.references :order_transaction, index: true
      t.string     :reason
      t.boolean    :partial_refund, default: false
      t.string     :message
      t.text       :merchant_response
      t.boolean    :test
      t.timestamps
    end
  end
end
