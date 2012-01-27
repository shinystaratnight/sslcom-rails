class CreateUnsubscribes < ActiveRecord::Migration
  def self.up
    create_table :unsubscribes, force: true do |t|
      t.string :specs
      t.text :domain, :email, :ref
      t.boolean :enforce
      t.timestamps
    end
  end

  def self.down
    drop_table :unsubscribes
  end
end
