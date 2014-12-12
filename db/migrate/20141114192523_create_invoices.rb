class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices, force: true do |t|
      t.references :order
      t.string  :description
      t.string  :company
      t.string  :first_name
      t.string  :last_name
      t.string  :address_1
      t.string  :address_2
      t.string  :country
      t.string  :city
      t.string  :state
      t.string  :postal_code
      t.string  :phone
      t.string  :fax
      t.string  :vat
      t.string  :tax
      t.string  :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :invoices
  end
  end
