class AdjustCertificateLookups < ActiveRecord::Migration
  def self.up
    change_table    :certificate_lookups do |t|
      t.remove   :signed_certificate_id
    end

    change_table    :csrs do |t|
      t.references   :certificate_lookup
    end
  end

  def self.down
    change_table    :certificate_lookups do |t|
      t.integer  :signed_certificate_id
    end

    change_table    :csrs do |t|
      t.remove   :certificate_lookup
    end
  end
end
