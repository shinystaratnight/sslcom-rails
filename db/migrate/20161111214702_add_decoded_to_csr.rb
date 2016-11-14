class AddDecodedToCsr < ActiveRecord::Migration
  def change
    add_column :csrs, :decoded, :text
  end
end
