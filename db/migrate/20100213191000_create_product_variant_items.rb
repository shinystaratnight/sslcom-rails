class CreateProductVariantItems < ActiveRecord::Migration
  def self.up
    create_table :product_variant_items do |t|
      t.references  :product_variant_group
      t.string    :title, :status
      t.text      :description, :text_only_description
      t.integer   :amount
      t.integer   :display_order
      t.string    :item_type
      t.string    :value
      t.string    :serial, :unique => true
      t.string    :published_as
      t.timestamps
    end
  end

  def self.down
    drop_table :product_variant_items
  end
end
