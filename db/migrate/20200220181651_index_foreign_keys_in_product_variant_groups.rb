class IndexForeignKeysInProductVariantGroups < ActiveRecord::Migration
  def change
    add_index :product_variant_groups, :variantable_id
  end
end
