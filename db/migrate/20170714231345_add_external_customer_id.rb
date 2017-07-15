class AddExternalCustomerId < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :ext_customer_ref, :string
    add_column :products, :ext_customer_ref, :string
    add_column :certificate_orders, :ext_customer_ref, :string
    add_column :certificate_contents, :ext_customer_ref, :string
    add_column :orders, :ext_customer_ref, :string
    add_column :csrs, :ext_customer_ref, :string
  end
end
