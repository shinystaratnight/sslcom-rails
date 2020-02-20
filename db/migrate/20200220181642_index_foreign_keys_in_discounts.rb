class IndexForeignKeysInDiscounts < ActiveRecord::Migration
  def change
    add_index :discounts, :discountable_id
  end
end
