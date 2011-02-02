class CreateCertificateOrders < ActiveRecord::Migration
  def self.up
    create_table :certificate_orders do |t|
      t.references  :ssl_account
      t.references  :validation
      t.references  :site_seal
      t.string      :workflow_state
      t.string      :ref
      t.integer     :num_domains, :server_licenses
      t.integer     :line_item_qty
      t.integer     :amount
      t.string      :notes
      t.timestamps
    end
  end

  def self.down
    drop_table  :certificate_orders
  end
end
