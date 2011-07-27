class CreateSubOrderItems < ActiveRecord::Migration
  def self.up
    create_table :sub_order_items, force: true do |t|
      t.references  :sub_itemable, :polymorphic=>true
      t.references  :product_variant_item
      t.integer     :quantity, :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :sub_order_items
  end
end
