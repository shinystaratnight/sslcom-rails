class CreateRenewalNotifications < ActiveRecord::Migration
  def self.up
    create_table :renewal_notifications, force: true do |t|
      t.references  :certificate_order
      t.text        :body
      t.string      :recipients, :subject
      t.timestamps
    end
  end

  def self.down
    drop_table :auto_renewals
  end
end
