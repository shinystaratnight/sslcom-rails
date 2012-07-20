class AddCertificateLookupToSignedCertificates < ActiveRecord::Migration
  def self.up
    change_table    :signed_certificates do |t|
      t.references  :certificate_lookup
    end
  end

  def self.down
    change_table    :signed_certificates do |t|
      t.remove      :certificate_lookup
    end
  end
end
