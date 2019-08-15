class ChangeCallbackTimezoneTypeOnCertificateOrderTokens < ActiveRecord::Migration
  def change
    change_column :certificate_order_tokens, :callback_timezone, :string
  end
end
