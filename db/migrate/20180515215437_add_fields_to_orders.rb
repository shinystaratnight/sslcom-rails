class AddFieldsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :cur_wildcard, :integer
    add_column :orders, :cur_non_wildcard, :integer
    add_column :orders, :max_wildcard, :integer
    add_column :orders, :max_non_wildcard, :integer
    add_column :orders, :wildcard_cents, :integer
    add_column :orders, :non_wildcard_cents, :integer
    add_column :orders, :reseller_tier_id, :integer
    
    change_column :orders, :invoice_description, :text
  end
end
