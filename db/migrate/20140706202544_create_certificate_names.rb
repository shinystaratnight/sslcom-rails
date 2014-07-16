class CreateCertificateNames < ActiveRecord::Migration
  def self.up
    create_table :certificate_names, force: true do |t|
      t.references  :certificate_content
      t.string      :email,:name
      t.boolean     :is_common_name
      t.timestamps
    end
  end

  def self.down
    drop_table :certificate_names
  end
end
