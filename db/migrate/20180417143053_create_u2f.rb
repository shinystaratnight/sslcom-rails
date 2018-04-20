class CreateU2f < ActiveRecord::Migration
  def self.up
    create_table :u2fs do |t|
      t.references  :user
      t.text        :certificate
      t.string      :key_handle, :public_key
      t.integer     :counter, :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :u2fs
  end
end
