class AddRequestStatusToCertificateOrders < ActiveRecord::Migration
  def change
    add_column :certificate_orders, :request_status, :string
  end
end
