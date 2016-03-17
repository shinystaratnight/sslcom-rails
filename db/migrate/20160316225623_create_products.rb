class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products, force: true do |t|
      t.string      :title, :status, :type, :value
      t.text        :summary, :text_only_summary, :description,
                    :text_only_description
      t.string      :published_as, :limit => 16, :default => 'draft'
      t.string      :serial, :unique => true
      t.string      :icons
      t.float       :amount
      t.string      :value
      t.text        :notes
      t.string      :display_order
      t.timestamps
    end

    create_table :products_sub_products, force: true do |t|
      t.references  :product
      t.integer     :sub_product_id
      t.timestamps
    end
  end

  def self.down
    drop_table  :products, :products_sub_products
  end
end
