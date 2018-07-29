class AddCaIdToCertificateContent < ActiveRecord::Migration
  def change
    add_reference :certificate_contents, :ca
  end
end
