
class AddDomainCountsToCertificateOrders < ActiveRecord::Migration
  def change
    add_column :certificate_orders, :wildcard_count, :integer
    add_column :certificate_orders, :nonwildcard_count, :integer
  end
end
