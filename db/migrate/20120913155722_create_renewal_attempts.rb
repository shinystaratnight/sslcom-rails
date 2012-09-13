class CreateRenewalAttempts < ActiveRecord::Migration
  def self.up
    create_table :renewal_attempts, force: true do |t|
      t.references  :certificate_order
      t.references  :order_transaction
      t.timestamps
    end
  end

  def self.down
    drop_table :renewal_attempts
  end
end
