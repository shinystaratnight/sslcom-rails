class AddPreferencesIndexes < ActiveRecord::Migration
  def change
    add_index :preferences, [:id,:owner_id,:owner_type], unique: true
  end
end
