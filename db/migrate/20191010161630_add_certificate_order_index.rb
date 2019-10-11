class AddCertificateOrderIndex < ActiveRecord::Migration
  def change
    add_index :certificate_orders, [:id, :workflow_state, :is_expired, :is_test], name: "index_certificate_orders_on_id_ws_ie_it"
  end
end
