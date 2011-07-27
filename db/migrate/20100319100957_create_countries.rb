class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries, force: true do |t|
      t.string    :iso1_code, :name_caps, :name, :iso3_code
      t.integer   :num_code
    end
  end

  def self.down
    drop_table :countries
  end
end