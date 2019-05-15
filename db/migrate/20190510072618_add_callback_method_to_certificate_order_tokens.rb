class AddCallbackMethodToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :callback_method, :string
  end
end
