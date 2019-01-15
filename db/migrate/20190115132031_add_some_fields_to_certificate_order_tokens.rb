class AddSomeFieldsToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :passed_token, :string
    add_column :certificate_order_tokens, :phone_verification_count, :integer
    add_column :certificate_order_tokens, :status, :string
  end
end
