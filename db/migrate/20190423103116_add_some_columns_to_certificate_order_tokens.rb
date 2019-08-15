class AddSomeColumnsToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :callback_type, :string
    add_column :certificate_order_tokens, :callback_timezone, :string
    add_column :certificate_order_tokens, :callback_datetime, :datetime
    add_column :certificate_order_tokens, :is_callback_done, :boolean
  end
end
