class AddVisitorTokenToOrders < ActiveRecord::Migration
  def self.up
    change_table :orders do |t|
      t.integer :visitor_token_id
    end
  end

  def self.down
    change_table :orders do |t|
      t.remove :visitor_token_id
    end
  end
end
