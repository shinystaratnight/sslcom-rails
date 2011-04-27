class CreateCsrOverrides < ActiveRecord::Migration
  def self.up
    create_table :csr_overrides do |t|
      t.references  :csr
      t.string  :common_name
			t.string  :organization
			t.string  :organization_unit
      t.string  :address_1
      t.string  :address_2
      t.string  :address_3
      t.string  :po_box
			t.string  :state
			t.string  :locality
      t.string  :postal_code
			t.string  :country

      t.timestamps
    end
  end

  def self.down
    drop_table :csrs
  end
end
