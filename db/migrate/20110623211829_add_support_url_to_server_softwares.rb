class AddSupportUrlToServerSoftwares < ActiveRecord::Migration
  def self.up
    change_table :server_softwares do |t|
      t.string  :support_url
    end
  end

  def self.down
    change_table :server_softwares do |t|
      t.remove  :support_url
    end
  end
end
