class AddToCdns < ActiveRecord::Migration
  def change
    add_column :cdns, :resource_id, :string
    add_column :cdns, :custom_domain_name, :string
    add_reference :cdns, :certificate_order, foreign_key: true
  end
end
