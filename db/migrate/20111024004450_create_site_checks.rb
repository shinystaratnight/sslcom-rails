class CreateSiteChecks < ActiveRecord::Migration
  def self.up
    create_table :site_checks, force: true do |t|
      t.text        :url
      t.references  :certificate_lookup
      t.timestamps
    end
  end

  def self.down
    drop_table :site_checks
  end
end
