class AddUniqueValueToCsrs < ActiveRecord::Migration
  def change
    add_column :csrs, :unique_value, :string
  end
end
