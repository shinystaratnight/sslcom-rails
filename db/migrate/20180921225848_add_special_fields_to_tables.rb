class AddSpecialFieldsToTables < ActiveRecord::Migration
  def change
    add_column :certificates, :special_fields, :string, default: "--- []"
    add_column :contacts, :special_fields, :text
  end
end
