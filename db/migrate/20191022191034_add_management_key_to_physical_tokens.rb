class AddManagementKeyToPhysicalTokens < ActiveRecord::Migration
  def change
    add_column :physical_tokens, :management_key, :string
  end
end
