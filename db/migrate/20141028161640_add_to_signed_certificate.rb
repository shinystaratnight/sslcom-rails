class AddToSignedCertificate < ActiveRecord::Migration
  def self.up
    change_table :signed_certificates do |t|
      t.text :decoded
    end
  end

  def self.down
    change_table :signed_certificates do |t|
      t.remove :decoded
    end
  end
end
