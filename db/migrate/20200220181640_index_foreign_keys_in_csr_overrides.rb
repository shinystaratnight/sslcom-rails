class IndexForeignKeysInCsrOverrides < ActiveRecord::Migration
  def change
    add_index :csr_overrides, :csr_id
  end
end
