class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.string :title, :limit => 50, :default => "" 
      t.text :note, :default => "" 
      t.references :notable, :polymorphic => true
      t.references :user
      t.timestamps
    end

    add_index :notes, :notable_type
    add_index :notes, :notable_id
    add_index :notes, :user_id
  end

  def self.down
    drop_table :notes
  end
end
