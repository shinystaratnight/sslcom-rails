class CreateCsrUniqueValues < ActiveRecord::Migration
  def change
    create_table :csr_unique_values do |t|
      t.string      :unique_value
      t.references  :csr
      t.timestamps
    end
  end
end
