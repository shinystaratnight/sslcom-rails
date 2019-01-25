class AddExpiresAtToCertificateOrder < ActiveRecord::Migration
  def change
    add_column :certificate_orders, :expires_at, :datetime
  end
end
