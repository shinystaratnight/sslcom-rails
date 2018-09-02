class RemoveUniqueValueFromCsr < ActiveRecord::Migration
  def change
    remove_column :csrs, :unique_value, :string
  end
end
