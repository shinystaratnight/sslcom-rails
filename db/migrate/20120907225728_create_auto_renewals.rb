class CreateAutoRenewals < ActiveRecord::Migration
  def self.up
    create_table :auto_renewals, force: true do |t|
      t.references  :certificate_order
      t.references  :order
      t.text        :body
      t.string      :recipients, :subject
      t.timestamps
    end
  end

  def self.down
    drop_table :auto_renewals
  end
end
