class AddCertificateLookupToSignedCertificates < ActiveRecord::Migration
  def self.up
    change_table    :signed_certificates, force: true do |t|
      t.references  :certificate_lookup
    end
  end

  def self.down
    change_table    :signed_certificates, force: true do |t|
      t.remove      :certificate_lookup
    end
  end
end
