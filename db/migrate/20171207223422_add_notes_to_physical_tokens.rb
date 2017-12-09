class AddNotesToPhysicalTokens < ActiveRecord::Migration
  def change
    add_column :physical_tokens, :notes, :text
    add_column :physical_tokens, :name, :string
    add_column :physical_tokens, :workflow_state, :string
  end
end
