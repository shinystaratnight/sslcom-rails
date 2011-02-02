class CreateProductVariantGroups < ActiveRecord::Migration
  def self.up
    create_table :product_variant_groups do |t|
      t.references  :variantable, :polymorphic=>true
      t.string    :title, :status
      t.text      :description, :text_only_description
      t.integer   :display_order
      t.string    :serial, :unique => true
      t.string    :published_as
      t.timestamps
    end
  end

  def self.down
    drop_table :product_variant_groups
  end
end
