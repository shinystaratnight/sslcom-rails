class IndexForeignKeysInDiscountablesSellables < ActiveRecord::Migration
  def change
    add_index :discountables_sellables, :discountable_id
    add_index :discountables_sellables, :sellable_id
  end
end
