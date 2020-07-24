# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  approval               :string(255)
#  billable_type          :string(255)
#  canceled_at            :datetime
#  cents                  :integer
#  cur_non_wildcard       :integer
#  cur_wildcard           :integer
#  currency               :string(255)
#  description            :string(255)
#  ext_affiliate_credited :boolean
#  ext_affiliate_name     :string(255)
#  ext_customer_ref       :string(255)
#  invoice_description    :text(65535)
#  lock_version           :integer          default("0")
#  max_non_wildcard       :integer
#  max_wildcard           :integer
#  non_wildcard_cents     :integer
#  notes                  :string(255)
#  paid_at                :datetime
#  po_number              :string(255)
#  quote_number           :string(255)
#  reference_number       :string(255)
#  state                  :string(255)      default("pending")
#  status                 :string(255)      default("active")
#  type                   :string(255)
#  wildcard_cents         :integer
#  created_at             :datetime
#  updated_at             :datetime
#  address_id             :integer
#  billable_id            :integer
#  billing_profile_id     :integer
#  deducted_from_id       :integer
#  ext_affiliate_id       :string(255)
#  invoice_id             :integer
#  reseller_tier_id       :integer
#  visitor_token_id       :integer
#
# Indexes
#
#  index_orders_on_address_id                               (address_id)
#  index_orders_on_billable_id                              (billable_id)
#  index_orders_on_billable_id_and_billable_type            (billable_id,billable_type)
#  index_orders_on_billable_type                            (billable_type)
#  index_orders_on_billing_profile_id                       (billing_profile_id)
#  index_orders_on_created_at                               (created_at)
#  index_orders_on_deducted_from_id                         (deducted_from_id)
#  index_orders_on_ext_affiliate_id                         (ext_affiliate_id)
#  index_orders_on_id_and_state                             (id,state)
#  index_orders_on_id_and_type                              (id,type)
#  index_orders_on_invoice_id                               (invoice_id)
#  index_orders_on_po_number                                (po_number)
#  index_orders_on_quote_number                             (quote_number)
#  index_orders_on_reference_number                         (reference_number)
#  index_orders_on_reseller_tier_id                         (reseller_tier_id)
#  index_orders_on_state_and_billable_id_and_billable_type  (state,billable_id,billable_type)
#  index_orders_on_state_and_description_and_notes          (state,description,notes)
#  index_orders_on_status                                   (status)
#  index_orders_on_updated_at                               (updated_at)
#  index_orders_on_visitor_token_id                         (visitor_token_id)
#

class ReprocessCertificateOrder < Order
    
end
