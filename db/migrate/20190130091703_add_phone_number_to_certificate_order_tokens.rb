class AddPhoneNumberToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :phone_number, :string
  end
end
