class AddFieldsToCertificates < ActiveRecord::Migration
  def change
    add_column :certificates, :ca_certificate_id, :integer
    add_column :cas, :type, :string, required: true
    
    add_index :certificates, :ca_certificate_id
  end
end
