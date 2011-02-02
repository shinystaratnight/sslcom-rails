class CreateDeposits < ActiveRecord::Migration
  def self.up
    create_table :deposits do |t|
      t.float       :amount
      t.string      :full_name
      t.string      :credit_card
      t.string      :last_digits
      t.string      :payment_method
      t.timestamps
    end
  end

  def self.down
    drop_table :deposits
  end
end