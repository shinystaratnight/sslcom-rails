class AddDuoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :duo_enabled, :string, :default => 'enabled'
  end
end
