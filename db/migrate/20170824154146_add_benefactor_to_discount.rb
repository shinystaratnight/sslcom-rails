class AddBenefactorToDiscount < ActiveRecord::Migration
  def self.up
    change_table :discounts, force: true do |t|
      t.references  :benefactor, :polymorphic=>true
    end
  end

  def self.down
    change_table :discounts, force: true do |t|
      t.remove  :benefactor
    end
  end
end
