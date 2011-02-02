class AddStatusToGroupings < ActiveRecord::Migration
  def self.up
    change_table :groupings do |t|
      t.string :status
    end
  end

  def self.down
    change_table :groupings do |t|
      t.remove :status
    end
  end
end
