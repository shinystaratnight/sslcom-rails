# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_orders
#
#  id                    :integer          not null, primary key
#  amount                :integer
#  auto_renew            :string(255)
#  auto_renew_status     :string(255)
#  ca                    :string(255)
#  expires_at            :datetime
#  ext_customer_ref      :string(255)
#  external_order_number :string(255)
#  is_expired            :boolean
#  is_test               :boolean
#  line_item_qty         :integer
#  nonwildcard_count     :integer
#  notes                 :text(65535)
#  num_domains           :integer
#  ref                   :string(255)
#  request_status        :string(255)
#  server_licenses       :integer
#  validation_type       :string(255)
#  wildcard_count        :integer
#  workflow_state        :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  acme_account_id       :string(255)
#  assignee_id           :integer
#  folder_id             :integer
#  renewal_id            :integer
#  site_seal_id          :integer
#  ssl_account_id        :integer
#  validation_id         :integer
#
# Indexes
#
#  index_certificate_orders_on_3_cols                         (workflow_state,is_expired,is_test)
#  index_certificate_orders_on_3_cols(2)                      (ssl_account_id,workflow_state,id)
#  index_certificate_orders_on_4_cols                         (ssl_account_id,workflow_state,is_test,updated_at)
#  index_certificate_orders_on_acme_account_id                (acme_account_id)
#  index_certificate_orders_on_assignee_id                    (assignee_id)
#  index_certificate_orders_on_created_at                     (created_at)
#  index_certificate_orders_on_folder_id                      (folder_id)
#  index_certificate_orders_on_id_and_ref_and_ssl_account_id  (id,ref,ssl_account_id)
#  index_certificate_orders_on_id_ws_ie_it                    (id,workflow_state,is_expired,is_test)
#  index_certificate_orders_on_is_expired                     (is_expired)
#  index_certificate_orders_on_is_test                        (is_test)
#  index_certificate_orders_on_ref                            (ref)
#  index_certificate_orders_on_renewal_id                     (renewal_id)
#  index_certificate_orders_on_ssl_account_id                 (ssl_account_id)
#  index_certificate_orders_on_test                           (id,is_test)
#  index_certificate_orders_on_validation_id                  (validation_id)
#  index_certificate_orders_on_workflow_state                 (id,workflow_state,is_expired,is_test) UNIQUE
#  index_certificate_orders_on_workflow_state_and_is_expired  (workflow_state,is_expired)
#  index_certificate_orders_on_workflow_state_and_renewal_id  (workflow_state,renewal_id)
#  index_certificate_orders_on_ws_ie_it_ua                    (workflow_state,is_expired,is_test)
#  index_certificate_orders_on_ws_ie_ri                       (workflow_state,is_expired,renewal_id)
#  index_certificate_orders_on_ws_is_ri                       (workflow_state,is_expired,renewal_id)
#  index_certificate_orders_r_eon_n                           (ref,external_order_number,notes)
#  index_certificate_orders_site_seal_id                      (site_seal_id)
#

FactoryBot.define do
  factory :certificate_order do
    workflow_state { 'paid' }
    ref { 'co-ee1eufn55' }
    amount { '11000' }
    ca { 'SSLcomSHA2' }
    ssl_account
    external_order_number { Faker::Alphanumeric.alphanumeric(number: 12) }
    notes { Faker::Lorem.paragraph }

    transient do
      include_tags { false }
    end

    after :create do |co, options|
      co.sub_order_items << create(:sub_order_item)
      co.taggings << Tagging.create(tag: create(:tag, ssl_account: co.ssl_account), taggable_id: co.id, taggable_type: 'CertificateOrder') if options.include_tags
    end
  end
end
