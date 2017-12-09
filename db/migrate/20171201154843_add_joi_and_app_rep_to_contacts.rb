class AddJoiAndAppRepToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :callback_method, :string
    add_column :contacts, :incorporation_date, :date
    add_column :contacts, :incorporation_country, :string
    add_column :contacts, :incorporation_state, :string
    add_column :contacts, :incorporation_city, :string
    add_column :contacts, :assumed_name, :string
    add_column :contacts, :business_category, :string
    add_column :contacts, :duns_number, :string
    add_column :contacts, :company_number, :string
    add_column :contacts, :registration_service, :string
  end
end
