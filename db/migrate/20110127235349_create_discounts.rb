class CreateDiscounts < ActiveRecord::Migration
  def self.up
    create_table :discounts do |t|
      t.references  :discountable, polymorphic: true
      t.string      :value
      t.string      :apply_as
      t.string      :label
      t.string      :ref
      t.datetime    :expires_at
      t.timestamps
    end
  end

  def self.down
    drop_table :discounts
  end
end
