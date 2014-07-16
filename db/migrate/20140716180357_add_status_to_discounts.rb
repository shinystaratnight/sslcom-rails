class AddStatusToDiscounts < ActiveRecord::Migration
  def self.up
    change_table    :discounts do |t|
      t.string      :status
      t.integer     :uses
    end
  end

  def self.down
    change_table    :discounts do |t|
      t.remove      :status, :uses
    end
  end
end
