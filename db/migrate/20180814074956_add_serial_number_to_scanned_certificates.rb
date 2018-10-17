class AddSerialNumberToScannedCertificates < ActiveRecord::Migration
  def self.up
    change_table  :scanned_certificates do |t|
      t.string  :serial
    end
  end

  def self.down
    change_table  :scanned_certificates do |t|
      t.remove  :serial
    end
  end
end
