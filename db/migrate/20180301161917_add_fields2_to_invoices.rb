class AddFields2ToInvoices < ActiveRecord::Migration
  def change
    change_column :invoices, :notes, :text
    add_column :invoices, :default_payment, :string
    
    add_column :billing_profiles, :default_profile, :boolean
  end
end
