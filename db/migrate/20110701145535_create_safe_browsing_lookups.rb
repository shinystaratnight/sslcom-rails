class CreateSafeBrowsingLookups < ActiveRecord::Migration
  def self.up
    create_table :safe_browsing_lookups do |t|
      t.references  :surl
      t.integer     :response_code
      t.string      :response_body

      t.timestamps
    end
  end

  def self.down
    drop_table :safe_browsing_lookups
  end
end
