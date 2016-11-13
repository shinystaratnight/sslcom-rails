class AdjustCertificateLookups < ActiveRecord::Migration
  def self.up
    change_table    :csrs, force: true do |t|
      t.references   :certificate_lookup
    end
  end

  def self.down
    change_table    :csrs do |t|
      t.remove   :certificate_lookup
    end
  end
end
