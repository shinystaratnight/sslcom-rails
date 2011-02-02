class CreateResellerTiers < ActiveRecord::Migration
  def self.up
    create_table :reseller_tiers do |t|
      t.string  :label
      t.string  :description
      t.integer :amount
      t.string  :roles
      t.string  :published_as
      t.timestamps
    end
  end

  def self.down
    drop_table :reseller_tiers
  end
end
