class AddPhoneCallCountToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :phone_call_count, :integer
  end
end
