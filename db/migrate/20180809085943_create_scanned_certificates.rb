class CreateScannedCertificates < ActiveRecord::Migration
  # def change
  #   create_table :scanned_certificates do |t|
  #   end
  # end

  def self.up
    create_table :scanned_certificates, force: true do |t|
      t.text  :body
      t.text  :decoded
      t.timestamps
    end
  end

  def self.down
    drop_table  :scanned_certificates
  end
end
