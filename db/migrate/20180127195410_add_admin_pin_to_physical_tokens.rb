class AddAdminPinToPhysicalTokens < ActiveRecord::Migration
  def change
    add_column :physical_tokens, :admin_pin, :string
  end
end
