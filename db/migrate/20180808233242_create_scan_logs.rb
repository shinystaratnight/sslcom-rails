class CreateScanLogs < ActiveRecord::Migration
  # def change
  #   create_table :scan_logs do |t|
  #   end
  # end

  def self.up
    create_table :scan_logs, force: true do |t|
      t.references  :notification_group
      t.references  :scanned_certificate
      t.string      :domain_name
      t.string      :scan_status
      t.timestamps
    end

    add_index :scan_logs, :notification_group_id
    add_index :scan_logs, :scanned_certificate_id
  end

  def self.down
    drop_table  :scan_logs
  end
end
