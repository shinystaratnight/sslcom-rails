class AddRenewalIndexToCertificateOrders < ActiveRecord::Migration
  def change
    add_index "certificate_orders", ["workflow_state", "is_expired", "renewal_id"],
              name: "index_certificate_orders_on_ws_ie_ri", using: :btree
    add_index "certificate_orders", ["workflow_state","renewal_id"], using: :btree
  end
end
