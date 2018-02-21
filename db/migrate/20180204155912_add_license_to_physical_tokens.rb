class AddLicenseToPhysicalTokens < ActiveRecord::Migration
  def change
    add_column :physical_tokens, :license, :string
  end
end
