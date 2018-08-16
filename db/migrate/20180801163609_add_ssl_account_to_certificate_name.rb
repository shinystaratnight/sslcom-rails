class AddSslAccountToCertificateName < ActiveRecord::Migration
  def change
    add_reference :certificate_names, :ssl_account
  end
end
