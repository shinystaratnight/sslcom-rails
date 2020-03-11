class RemoveProducts < ActiveRecord::Migration
  def change
    drop_table :products if table_exists?(:products)
  end
end
