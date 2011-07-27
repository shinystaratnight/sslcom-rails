class CreateBillableTables < ActiveRecord::Migration
  def self.up
    create_table :gateways, :force => true do |t|
      t.column :service, :string
      t.column :login, :string
      t.column :password, :string
      t.column :mode, :string
    end

    create_table :line_items, force: true do |t|
      t.references :order
      t.references :affiliate
      t.integer     :sellable_id
      t.string      :sellable_type
      t.integer     :cents
      t.string      :currency
      t.float       :affiliate_payout_rate
    end

    add_index :line_items, :order_id
    add_index :line_items, :sellable_id
    add_index :line_items, :sellable_type

    create_table :orders, :force => true do |t|
      t.references  :billing_profile
      t.column :billable_id, :integer
      t.column :billable_type, :string
      t.column :address_id, :integer
      t.column :cents, :integer
      t.column :currency, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :paid_at, :datetime
      t.column :canceled_at, :datetime
      t.column :lock_version, :integer, :default => 0
      t.column :description, :string
      t.column :state, :string, :default => 'pending'
      t.column :status, :string, :default => 'active'
      t.column :reference_number, :string
      t.column :deducted_from_id, :integer
      t.string :po_number, :quote_number
      t.column :notes, :string
    end

    add_index :orders, :billable_id
    add_index :orders, :billable_type
    add_index :orders, :created_at
    add_index :orders, :updated_at

    create_table :payments, :force => true do |t|
      t.column :order_id, :integer
      t.column :address_id, :integer
      t.column :cents, :integer
      t.column :currency, :string
      t.column :confirmation, :string
      t.column :cleared_at, :datetime
      t.column :voided_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :lock_version, :integer, :default => 0
    end

    add_index :payments, :order_id
    add_index :payments, :cleared_at
    add_index :payments, :created_at
    add_index :payments, :updated_at

    create_table :addresses, :force => true do |t|
      t.column :name, :string
      t.column :street1, :string
      t.column :street2, :string
      t.column :locality, :string
      t.column :region, :string
      t.column :postal_code, :string
      t.column :country, :string
      t.column :phone, :string
    end
  end

  def self.down
    drop_table :line_items
    drop_table :orders
    drop_table :payments
    drop_table :gateways
    drop_table :addresses
  end
end
