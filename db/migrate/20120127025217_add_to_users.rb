class AddToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string  :notes
      t.boolean :is_auth_token
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :is_auth_token, :notes
    end
  end
end
