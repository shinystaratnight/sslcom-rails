class AddCaaPassedToCertificateNames < ActiveRecord::Migration
  # def change
  # end

  def self.up
    change_table :certificate_names do |t|
      t.boolean :caa_passed, :default => false
    end
  end

  def self.down
    change_talbe :certificate_names do |t|
      t.remove  :caa_passed
    end
  end
end
