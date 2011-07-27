class CreateServerSoftwares < ActiveRecord::Migration
  def self.up
    create_table :server_softwares, force: true do |t|
      t.string  :title, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :server_softwares
  end
end
