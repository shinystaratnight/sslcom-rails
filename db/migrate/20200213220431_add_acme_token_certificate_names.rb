class AddAcmeTokenCertificateNames < ActiveRecord::Migration
  def change
    add_column :certificate_names, :acme_token, :string, index: true
  end
end
