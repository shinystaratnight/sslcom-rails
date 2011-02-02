class CreateCsrs < ActiveRecord::Migration
  def self.up
    create_table :csrs do |t|
      t.references  :certificate_content
      t.text    :body
      t.integer :duration
      t.string  :common_name
			t.string  :organization
			t.string  :organization_unit
			t.string  :state
			t.string  :locality
			t.string  :country
			t.string  :email
			t.string  :sig_alg

      t.timestamps
    end
  end

  def self.down
    drop_table :csrs
  end
end
