class AddAgreementToCertificateContent < ActiveRecord::Migration
  def self.up
    add_column :certificate_contents, :agreement, :boolean
  end

  def self.down
    remove_column :certificate_contents, :agreement
  end
end
