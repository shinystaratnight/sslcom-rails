class AddMiscIndexes < ActiveRecord::Migration
  def self.up
    add_index :csrs, :common_name
    add_index :csrs, :organization

    add_index :users, :login

    add_index :certificate_orders, :ref
    add_index :certificate_orders, :created_at

    add_index :orders, :reference_number
    add_index :orders, :po_number
    add_index :orders, :quote_number
  end

  def self.down
    remove_index :csrs, :common_name
    remove_index :csrs, :organization

    remove_index :users, :login

    remove_index :certificate_orders, :ref
    remove_index :certificate_orders, :created_at

    remove_index :orders, :reference_number
    remove_index :orders, :po_number
    remove_index :orders, :quote_number
  end
end
