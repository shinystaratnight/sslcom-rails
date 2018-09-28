class AddEpkiAgreementToSslAccount < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :epki_agreement, :timestamp
  end
end
