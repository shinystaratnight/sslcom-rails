class CreateDiscountablesSellables < ActiveRecord::Migration
  def up
    # discountable is any object that can receive a discount ie SslAccount or ResellerTier (grouping)
    # sellable is any item that can be sold. Must have a price and be able to be added to a LineItem
    create_table :discountables_sellables, force: true do |t|
      t.integer   :discountable_id
      t.string    :discountable_type
      t.integer   :sellable_id
      t.string    :sellable_type
      t.string    :amount
      t.string    :apply_as # percentage or absolute
      t.string    :status
      t.text      :notes
      t.timestamps
    end
  end

  def down
    drop_table    :discountables_sellables
  end
end
