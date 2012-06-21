class AddAffUrlToLineItems < ActiveRecord::Migration
  def self.up
    change_table :line_items do |t|
      t.string :aff_url
    end
  end

  def self.down
    change_table :trackings do |t|
      t.remove :aff_url
    end
  end
end
