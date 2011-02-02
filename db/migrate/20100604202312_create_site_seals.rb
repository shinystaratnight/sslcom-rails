class CreateSiteSeals < ActiveRecord::Migration
  def self.up
    create_table :site_seals do |t|
      t.string      :workflow_state
      t.string      :seal_type
      t.string      :ref
      t.timestamps
    end
  end

  def self.down
    drop_table :site_seals
  end
end
