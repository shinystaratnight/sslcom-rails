class AdjustCertificateOrder < ActiveRecord::Migration
  def self.up
    change_table    :certificate_orders do |t|
      t.string      :auto_renew
      t.string      :auto_renew_status
    end
  end

  def self.down
    change_table    :certificate_orders do |t|
      t.remove      :auto_renew
      t.remove      :auto_renew_status
    end
  end
end
