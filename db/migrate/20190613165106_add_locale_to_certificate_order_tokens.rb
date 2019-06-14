class AddLocaleToCertificateOrderTokens < ActiveRecord::Migration
  def change
    add_column :certificate_order_tokens, :locale, :string
  end
end
