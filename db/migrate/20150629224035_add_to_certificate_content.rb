class AddToCertificateContent < ActiveRecord::Migration
  def self.up
    change_table :certificate_contents do |t|
      t.string :label
      t.string :ref
    end
  end

  def self.down
    change_table :certificate_contents do |t|
      t.remove :label
      t.remove :ref
    end
  end
end
