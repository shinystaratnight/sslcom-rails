class AddCountryCodeToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :country_code, :string
  end
end
