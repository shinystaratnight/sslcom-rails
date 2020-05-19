# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200312160424) do

  create_table "addresses", force: :cascade do |t|
    t.string "name",        :limit=>255
    t.string "street1",     :limit=>255
    t.string "street2",     :limit=>255
    t.string "locality",    :limit=>255
    t.string "region",      :limit=>255
    t.string "postal_code", :limit=>255
    t.string "country",     :limit=>255
    t.string "phone",       :limit=>255
  end

  create_table "affiliates", force: :cascade do |t|
    t.integer  "ssl_account_id",      :limit=>4, :index=>{:name=>"index_affiliates_on_ssl_account_id", :using=>:btree}
    t.string   "first_name",          :limit=>255
    t.string   "last_name",           :limit=>255
    t.string   "email",               :limit=>255
    t.string   "phone",               :limit=>255
    t.string   "organization",        :limit=>255
    t.string   "address1",            :limit=>255
    t.string   "address2",            :limit=>255
    t.string   "postal_code",         :limit=>255
    t.string   "city",                :limit=>255
    t.string   "state",               :limit=>255
    t.string   "country",             :limit=>255
    t.string   "website",             :limit=>255
    t.string   "contact_email",       :limit=>255
    t.string   "contact_phone",       :limit=>255
    t.string   "tax_number",          :limit=>255
    t.string   "payout_method",       :limit=>255
    t.string   "payout_threshold",    :limit=>255
    t.string   "payout_frequency",    :limit=>255
    t.string   "bank_name",           :limit=>255
    t.string   "bank_routing_number", :limit=>255
    t.string   "bank_account_number", :limit=>255
    t.string   "swift_code",          :limit=>255
    t.string   "checks_payable_to",   :limit=>255
    t.string   "epassporte_account",  :limit=>255
    t.string   "paypal_account",      :limit=>255
    t.string   "type_organization",   :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.integer  "user_id",    :limit=>4
    t.string   "user_type",  :limit=>255
    t.text     "to",         :limit=>65535
    t.string   "mailer",     :limit=>255
    t.text     "subject",    :limit=>65535
    t.datetime "sent_at"
    t.string   "token",      :limit=>255, :index=>{:name=>"index_ahoy_messages_on_token", :using=>:btree}
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.text     "content",    :limit=>65535
  end

  create_table "api_credentials", force: :cascade do |t|
    t.integer  "ssl_account_id",               :limit=>4, :index=>{:name=>"index_api_credentials_on_ssl_account_id", :using=>:btree}
    t.string   "account_key",                  :limit=>255, :index=>{:name=>"index_api_credentials_on_account_key_and_secret_key", :with=>["secret_key"], :unique=>true, :using=>:btree}
    t.string   "secret_key",                   :limit=>255
    t.datetime "created_at",                   :null=>false
    t.datetime "updated_at",                   :null=>false
    t.string   "roles",                        :limit=>255
    t.string   "hmac_key",                     :limit=>255
    t.string   "acme_acct_pub_key_thumbprint", :limit=>255, :index=>{:name=>"index_api_credentials_on_acme_acct_pub_key_thumbprint", :using=>:btree}
  end

  create_table "apis", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer  "user_id",        :limit=>4, :index=>{:name=>"index_assignments_on_user_id", :using=>:btree}
    t.integer  "role_id",        :limit=>4, :index=>{:name=>"index_assignments_on_role_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ssl_account_id", :limit=>4, :index=>{:name=>"index_assignments_on_ssl_account_id", :using=>:btree}
  end
  add_index "assignments", ["user_id", "ssl_account_id", "role_id"], :name=>"index_assignments_on_user_id_and_ssl_account_id_and_role_id", :using=>:btree
  add_index "assignments", ["user_id", "ssl_account_id"], :name=>"index_assignments_on_user_id_and_ssl_account_id", :using=>:btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",    :limit=>4, :index=>{:name=>"index_authentications_on_user_id", :using=>:btree}
    t.string   "provider",   :limit=>255
    t.string   "uid",        :limit=>255
    t.string   "email",      :limit=>255
    t.string   "first_name", :limit=>255
    t.string   "last_name",  :limit=>255
    t.string   "nick_name",  :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auto_renewals", force: :cascade do |t|
    t.integer  "certificate_order_id", :limit=>4
    t.integer  "order_id",             :limit=>4
    t.text     "body",                 :limit=>65535
    t.string   "recipients",           :limit=>255
    t.string   "subject",              :limit=>255
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "billing_profiles", force: :cascade do |t|
    t.integer  "ssl_account_id",             :limit=>4, :index=>{:name=>"index_billing_profile_on_ssl_account_id", :using=>:btree}
    t.string   "description",                :limit=>255
    t.string   "first_name",                 :limit=>255
    t.string   "last_name",                  :limit=>255
    t.string   "address_1",                  :limit=>255
    t.string   "address_2",                  :limit=>255
    t.string   "country",                    :limit=>255
    t.string   "city",                       :limit=>255
    t.string   "state",                      :limit=>255
    t.string   "postal_code",                :limit=>255
    t.string   "phone",                      :limit=>255
    t.string   "company",                    :limit=>255
    t.string   "credit_card",                :limit=>255
    t.string   "card_number",                :limit=>255
    t.integer  "expiration_month",           :limit=>4
    t.integer  "expiration_year",            :limit=>4
    t.string   "security_code",              :limit=>255
    t.string   "last_digits",                :limit=>255
    t.binary   "data",                       :limit=>65535
    t.binary   "salt",                       :limit=>65535
    t.string   "notes",                      :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_card_number",      :limit=>255
    t.string   "encrypted_card_number_salt", :limit=>255
    t.string   "encrypted_card_number_iv",   :limit=>255
    t.string   "vat",                        :limit=>255
    t.string   "tax",                        :limit=>255
    t.string   "status",                     :limit=>255
    t.boolean  "default_profile"
  end

  create_table "blocklists", force: :cascade do |t|
    t.string   "type",        :limit=>255
    t.string   "domain",      :limit=>255
    t.integer  "validation",  :limit=>4
    t.string   "status",      :limit=>255
    t.string   "reason",      :limit=>255
    t.string   "description", :limit=>255
    t.text     "notes",       :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "blocklists", ["id", "type"], :name=>"index_blocklists_on_id_and_type", :using=>:btree

  create_table "ca_api_requests", force: :cascade do |t|
    t.integer  "api_requestable_id",   :limit=>4, :index=>{:name=>"index_ca_api_requests_on_api_requestable", :with=>["api_requestable_type"], :using=>:btree}
    t.string   "api_requestable_type", :limit=>191
    t.text     "request_url",          :limit=>65535
    t.text     "parameters",           :limit=>65535
    t.string   "method",               :limit=>255
    t.text     "response",             :limit=>16777215
    t.string   "type",                 :limit=>191, :index=>{:name=>"index_ca_api_requests_on_type_and_username", :with=>["username"], :using=>:btree}
    t.string   "ca",                   :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_request",          :limit=>65535
    t.text     "request_method",       :limit=>65535
    t.string   "username",             :limit=>255, :index=>{:name=>"index_ca_api_requests_on_username_and_approval_id", :with=>["approval_id"], :unique=>true, :using=>:btree}
    t.string   "approval_id",          :limit=>255
    t.text     "certificate_chain",    :limit=>65535
  end
  add_index "ca_api_requests", ["id", "api_requestable_id", "api_requestable_type", "type", "created_at"], :name=>"index_ca_api_requests_on_type_and_api_requestable_and_created_at", :using=>:btree
  add_index "ca_api_requests", ["id", "api_requestable_id", "api_requestable_type", "type"], :name=>"index_ca_api_requests_on_type_and_api_requestable", :unique=>true, :using=>:btree
  add_index "ca_api_requests", ["id", "type"], :name=>"index_ca_api_requests_on_id_and_type", :using=>:btree

  create_table "caa_checks", force: :cascade do |t|
    t.integer  "checkable_id",   :limit=>4, :index=>{:name=>"index_caa_checks_on_checkable_id_and_checkable_type", :with=>["checkable_type"], :using=>:btree}
    t.string   "checkable_type", :limit=>255
    t.string   "domain",         :limit=>255
    t.string   "request",        :limit=>255
    t.text     "result",         :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cas", force: :cascade do |t|
    t.string  "ref",             :limit=>255
    t.string  "friendly_name",   :limit=>255
    t.string  "profile_name",    :limit=>255
    t.string  "algorithm",       :limit=>255
    t.integer "size",            :limit=>4
    t.string  "description",     :limit=>255
    t.string  "caa_issuers",     :limit=>255
    t.string  "host",            :limit=>255
    t.string  "admin_host",      :limit=>255
    t.string  "ekus",            :limit=>255
    t.string  "end_entity",      :limit=>255
    t.string  "ca_name",         :limit=>255
    t.string  "type",            :limit=>255
    t.string  "client_cert",     :limit=>255
    t.string  "client_key",      :limit=>255
    t.string  "client_password", :limit=>255
  end
  add_index "cas", ["id", "type"], :name=>"index_cas_on_id_and_type", :using=>:btree

  create_table "cas_certificates", force: :cascade do |t|
    t.integer  "certificate_id", :limit=>4, :null=>false, :index=>{:name=>"index_cas_certificates_on_certificate_id", :using=>:btree}
    t.integer  "ca_id",          :limit=>4, :null=>false, :index=>{:name=>"index_cas_certificates_on_ca_id", :using=>:btree}
    t.string   "status",         :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ssl_account_id", :limit=>4, :index=>{:name=>"index_cas_certificates_on_ssl_account_id", :using=>:btree}
  end
  add_index "cas_certificates", ["certificate_id", "ca_id"], :name=>"index_cas_certificates_on_certificate_id_and_ca_id", :using=>:btree

  create_table "certificate_orders", force: :cascade do |t|
    t.integer  "ssl_account_id",        :limit=>4, :index=>{:name=>"index_certificate_orders_on_ssl_account_id", :using=>:btree}
    t.integer  "validation_id",         :limit=>4, :index=>{:name=>"index_certificate_orders_on_validation_id", :using=>:btree}
    t.integer  "site_seal_id",          :limit=>4, :index=>{:name=>"index_certificate_orders_site_seal_id", :using=>:btree}
    t.string   "workflow_state",        :limit=>255, :index=>{:name=>"index_certificate_orders_on_3_cols", :with=>["is_expired", "is_test"], :using=>:btree}
    t.string   "ref",                   :limit=>255, :index=>{:name=>"index_certificate_orders_on_ref", :using=>:btree}
    t.integer  "num_domains",           :limit=>4
    t.integer  "server_licenses",       :limit=>4
    t.integer  "line_item_qty",         :limit=>4
    t.integer  "amount",                :limit=>4
    t.text     "notes",                 :limit=>65535
    t.datetime "created_at",            :index=>{:name=>"index_certificate_orders_on_created_at", :using=>:btree}
    t.datetime "updated_at"
    t.boolean  "is_expired",            :index=>{:name=>"index_certificate_orders_on_is_expired", :using=>:btree}
    t.integer  "renewal_id",            :limit=>4, :index=>{:name=>"index_certificate_orders_on_renewal_id", :using=>:btree}
    t.boolean  "is_test",               :index=>{:name=>"index_certificate_orders_on_is_test", :using=>:btree}
    t.string   "auto_renew",            :limit=>255
    t.string   "auto_renew_status",     :limit=>255
    t.string   "ca",                    :limit=>255
    t.string   "external_order_number", :limit=>255
    t.string   "ext_customer_ref",      :limit=>255
    t.string   "validation_type",       :limit=>255
    t.string   "acme_account_id",       :limit=>255
    t.integer  "wildcard_count",        :limit=>4
    t.integer  "nonwildcard_count",     :limit=>4
    t.integer  "folder_id",             :limit=>4, :index=>{:name=>"index_certificate_orders_on_folder_id", :using=>:btree}
    t.integer  "assignee_id",           :limit=>4, :index=>{:name=>"index_certificate_orders_on_assignee_id", :using=>:btree}
    t.datetime "expires_at"
    t.string   "request_status",        :limit=>255
  end
  add_index "certificate_orders", ["id", "is_test"], :name=>"index_certificate_orders_on_test", :using=>:btree
  add_index "certificate_orders", ["id", "ref", "ssl_account_id"], :name=>"index_certificate_orders_on_id_and_ref_and_ssl_account_id", :using=>:btree
  add_index "certificate_orders", ["id", "workflow_state", "is_expired", "is_test"], :name=>"index_certificate_orders_on_id_ws_ie_it", :using=>:btree
  add_index "certificate_orders", ["id", "workflow_state", "is_expired", "is_test"], :name=>"index_certificate_orders_on_workflow_state", :unique=>true, :using=>:btree
  add_index "certificate_orders", ["ref", "external_order_number", "notes"], :name=>"index_certificate_orders_r_eon_n", :type=>:fulltext
  add_index "certificate_orders", ["ssl_account_id", "workflow_state", "id"], :name=>"index_certificate_orders_on_3_cols(2)", :using=>:btree
  add_index "certificate_orders", ["ssl_account_id", "workflow_state", "is_test", "updated_at"], :name=>"index_certificate_orders_on_4_cols", :using=>:btree
  add_index "certificate_orders", ["workflow_state", "is_expired", "is_test"], :name=>"index_certificate_orders_on_ws_ie_it_ua", :using=>:btree
  add_index "certificate_orders", ["workflow_state", "is_expired", "renewal_id"], :name=>"index_certificate_orders_on_ws_ie_ri", :using=>:btree
  add_index "certificate_orders", ["workflow_state", "is_expired", "renewal_id"], :name=>"index_certificate_orders_on_ws_is_ri", :using=>:btree
  add_index "certificate_orders", ["workflow_state", "is_expired"], :name=>"index_certificate_orders_on_workflow_state_and_is_expired", :using=>:btree
  add_index "certificate_orders", ["workflow_state", "renewal_id"], :name=>"index_certificate_orders_on_workflow_state_and_renewal_id", :using=>:btree

  create_table "cdns", force: :cascade do |t|
    t.integer  "ssl_account_id",       :limit=>4, :index=>{:name=>"index_cdns_on_ssl_account_id", :using=>:btree}
    t.string   "api_key",              :limit=>255
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
    t.string   "resource_id",          :limit=>255
    t.string   "custom_domain_name",   :limit=>255
    t.integer  "certificate_order_id", :limit=>4, :index=>{:name=>"fk_rails_486d5cc190", :using=>:btree}, :foreign_key=>{:references=>"certificate_orders", :name=>"fk_rails_486d5cc190", :on_update=>:restrict, :on_delete=>:restrict}
    t.boolean  "is_ssl_req",           :default=>false
  end

  create_table "certificate_api_requests", force: :cascade do |t|
    t.integer  "server_software_id",                :limit=>4
    t.integer  "country_id",                        :limit=>4
    t.string   "account_key",                       :limit=>255
    t.string   "secret_key",                        :limit=>255
    t.boolean  "test"
    t.string   "product",                           :limit=>255
    t.integer  "period",                            :limit=>4
    t.integer  "server_count",                      :limit=>4
    t.string   "other_domains",                     :limit=>255
    t.string   "common_names_flag",                 :limit=>255
    t.text     "csr",                               :limit=>65535
    t.string   "organization_name",                 :limit=>255
    t.string   "post_office_box",                   :limit=>255
    t.string   "street_address_1",                  :limit=>255
    t.string   "street_address_2",                  :limit=>255
    t.string   "street_address_3",                  :limit=>255
    t.string   "locality_name",                     :limit=>255
    t.string   "state_or_province_name",            :limit=>255
    t.string   "postal_code",                       :limit=>255
    t.string   "duns_number",                       :limit=>255
    t.string   "company_number",                    :limit=>255
    t.string   "registered_locality_name",          :limit=>255
    t.string   "registered_state_or_province_name", :limit=>255
    t.string   "registered_country_name",           :limit=>255
    t.string   "assumed_name",                      :limit=>255
    t.string   "business_category",                 :limit=>255
    t.string   "email_address",                     :limit=>255
    t.string   "contact_email_address",             :limit=>255
    t.string   "dcv_email_address",                 :limit=>255
    t.string   "ca_certificate_id",                 :limit=>255
    t.date     "incorporation_date"
    t.boolean  "is_customer_validated"
    t.boolean  "hide_certificate_reference"
    t.string   "external_order_number",             :limit=>255
    t.string   "external_order_number_constraint",  :limit=>255
    t.string   "response",                          :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificate_contents", force: :cascade do |t|
    t.integer  "certificate_order_id", :limit=>4, :null=>false, :index=>{:name=>"index_certificate_contents_on_certificate_order_id", :using=>:btree}
    t.text     "signing_request",      :limit=>65535
    t.text     "signed_certificate",   :limit=>65535
    t.integer  "server_software_id",   :limit=>4, :index=>{:name=>"index_certificate_contents_on_server_software_id", :using=>:btree}
    t.text     "domains",              :limit=>65535
    t.integer  "duration",             :limit=>4
    t.string   "workflow_state",       :limit=>255, :index=>{:name=>"index_certificate_contents_on_workflow_state", :using=>:btree}
    t.boolean  "billing_checkbox"
    t.boolean  "validation_checkbox"
    t.boolean  "technical_checkbox"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label",                :limit=>255
    t.string   "ref",                  :limit=>255, :index=>{:name=>"index_certificate_contents_on_ref", :using=>:btree}
    t.boolean  "agreement"
    t.string   "ext_customer_ref",     :limit=>255
    t.string   "approval",             :limit=>255
    t.integer  "ca_id",                :limit=>4, :index=>{:name=>"index_certificate_contents_on_ca_id", :using=>:btree}
  end

  create_table "certificate_enrollment_requests", force: :cascade do |t|
    t.integer  "certificate_id",     :limit=>4, :null=>false, :index=>{:name=>"index_certificate_enrollment_requests_on_certificate_id", :using=>:btree}
    t.integer  "ssl_account_id",     :limit=>4, :null=>false, :index=>{:name=>"index_certificate_enrollment_requests_on_ssl_account_id", :using=>:btree}
    t.integer  "user_id",            :limit=>4, :index=>{:name=>"index_certificate_enrollment_requests_on_user_id", :using=>:btree}
    t.integer  "order_id",           :limit=>4, :index=>{:name=>"index_certificate_enrollment_requests_on_order_id", :using=>:btree}
    t.integer  "duration",           :limit=>4, :null=>false
    t.text     "domains",            :limit=>65535, :null=>false
    t.text     "common_name",        :limit=>65535
    t.text     "signing_request",    :limit=>65535
    t.integer  "server_software_id", :limit=>4
    t.integer  "status",             :limit=>4
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
  end

  create_table "certificate_lookups", force: :cascade do |t|
    t.text     "certificate", :limit=>65535
    t.string   "serial",      :limit=>255
    t.string   "common_name", :limit=>255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
  end

  create_table "certificate_names", force: :cascade do |t|
    t.integer  "certificate_content_id", :limit=>4, :index=>{:name=>"index_certificate_names_on_certificate_content_id", :using=>:btree}
    t.string   "email",                  :limit=>255
    t.string   "name",                   :limit=>255, :index=>{:name=>"index_certificate_names_on_name", :using=>:btree}
    t.boolean  "is_common_name"
    t.datetime "created_at",             :null=>false
    t.datetime "updated_at",             :null=>false
    t.string   "acme_account_id",        :limit=>255
    t.integer  "ssl_account_id",         :limit=>4, :index=>{:name=>"index_certificate_names_on_ssl_account_id", :using=>:btree}
    t.boolean  "caa_passed",             :default=>false
    t.string   "acme_token",             :limit=>255, :index=>{:name=>"index_certificate_names_on_acme_token", :using=>:btree}
  end

  create_table "certificate_order_domains", force: :cascade do |t|
    t.integer "certificate_order_id", :limit=>4, :index=>{:name=>"index_certificate_order_domains_on_certificate_order_id", :using=>:btree}
    t.integer "domain_id",            :limit=>4, :index=>{:name=>"index_certificate_order_domains_on_domain_id", :using=>:btree}
  end

  create_table "certificate_order_managed_csrs", force: :cascade do |t|
    t.integer  "certificate_order_id", :limit=>4, :index=>{:name=>"index_certificate_order_managed_csrs_on_certificate_order_id", :using=>:btree}
    t.integer  "managed_csr_id",       :limit=>4, :index=>{:name=>"index_certificate_order_managed_csrs_on_managed_csr_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificate_order_tokens", force: :cascade do |t|
    t.integer  "certificate_order_id",     :limit=>4, :index=>{:name=>"index_certificate_order_tokens_on_certificate_order_id", :using=>:btree}
    t.integer  "user_id",                  :limit=>4, :index=>{:name=>"index_certificate_order_tokens_on_user_id", :using=>:btree}
    t.integer  "ssl_account_id",           :limit=>4, :index=>{:name=>"index_certificate_order_tokens_on_ssl_account_id", :using=>:btree}
    t.string   "token",                    :limit=>255
    t.boolean  "is_expired"
    t.datetime "due_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "passed_token",             :limit=>255
    t.integer  "phone_verification_count", :limit=>4
    t.string   "status",                   :limit=>255
    t.integer  "phone_call_count",         :limit=>4
    t.string   "phone_number",             :limit=>255
    t.string   "callback_type",            :limit=>255
    t.string   "callback_timezone",        :limit=>255
    t.datetime "callback_datetime"
    t.boolean  "is_callback_done"
    t.string   "callback_method",          :limit=>255
    t.string   "locale",                   :limit=>255
  end

  create_table "certificates", force: :cascade do |t|
    t.integer  "reseller_tier_id",      :limit=>4, :index=>{:name=>"index_certificates_on_reseller_tier_id", :using=>:btree}
    t.string   "title",                 :limit=>255
    t.string   "status",                :limit=>255
    t.text     "summary",               :limit=>65535
    t.text     "text_only_summary",     :limit=>65535
    t.text     "description",           :limit=>65535
    t.text     "text_only_description", :limit=>65535
    t.boolean  "allow_wildcard_ucc"
    t.string   "published_as",          :limit=>16, :default=>"draft"
    t.string   "serial",                :limit=>255
    t.string   "product",               :limit=>255
    t.string   "icons",                 :limit=>255
    t.string   "display_order",         :limit=>255
    t.string   "roles",                 :limit=>255, :default=>"--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "special_fields",        :limit=>255, :default=>"--- []"
  end

  create_table "certificates_products", force: :cascade do |t|
    t.integer  "certificate_id", :limit=>4, :index=>{:name=>"index_certificates_products_on_certificate_id", :using=>:btree}
    t.integer  "product_id",     :limit=>4, :index=>{:name=>"index_certificates_products_on_product_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "certificates_products", ["certificate_id", "product_id"], :name=>"index_certificates_products_on_certificate_id_and_product_id", :using=>:btree

  create_table "contact_validation_histories", force: :cascade do |t|
    t.integer  "contact_id",            :limit=>4, :null=>false, :index=>{:name=>"index_contact_validation_histories_on_contact_id", :using=>:btree}
    t.integer  "validation_history_id", :limit=>4, :null=>false, :index=>{:name=>"index_contact_validation_histories_on_validation_history_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "contact_validation_histories", ["contact_id", "validation_history_id"], :name=>"index_cont_val_histories_on_contact_id_and_validation_history_id", :using=>:btree

  create_table "contacts", force: :cascade do |t|
    t.string   "title",                 :limit=>255
    t.string   "first_name",            :limit=>255, :index=>{:name=>"index_contacts_on_16", :with=>["last_name", "company_name", "department", "po_box", "address1", "address2", "address3", "city", "state", "country", "postal_code", "email", "notes", "assumed_name", "duns_number"], :type=>:fulltext}
    t.string   "last_name",             :limit=>255
    t.string   "company_name",          :limit=>255
    t.string   "department",            :limit=>255
    t.string   "po_box",                :limit=>255
    t.string   "address1",              :limit=>255
    t.string   "address2",              :limit=>255
    t.string   "address3",              :limit=>255
    t.string   "city",                  :limit=>255
    t.string   "state",                 :limit=>255
    t.string   "country",               :limit=>255
    t.string   "postal_code",           :limit=>255
    t.string   "email",                 :limit=>255
    t.string   "phone",                 :limit=>255
    t.string   "ext",                   :limit=>255
    t.string   "fax",                   :limit=>255
    t.string   "notes",                 :limit=>255
    t.string   "type",                  :limit=>255, :index=>{:name=>"index_contacts_on_type_and_contactable_type", :with=>["contactable_type"], :using=>:btree}
    t.string   "roles",                 :limit=>255, :default=>"--- []"
    t.integer  "contactable_id",        :limit=>4, :index=>{:name=>"index_contacts_on_contactable_id_and_contactable_type", :with=>["contactable_type"], :using=>:btree}
    t.string   "contactable_type",      :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "registrant_type",       :limit=>4
    t.integer  "parent_id",             :limit=>4, :index=>{:name=>"index_contacts_on_parent_id", :using=>:btree}
    t.string   "callback_method",       :limit=>255
    t.date     "incorporation_date"
    t.string   "incorporation_country", :limit=>255
    t.string   "incorporation_state",   :limit=>255
    t.string   "incorporation_city",    :limit=>255
    t.string   "assumed_name",          :limit=>255
    t.string   "business_category",     :limit=>255
    t.string   "duns_number",           :limit=>255
    t.string   "company_number",        :limit=>255
    t.string   "registration_service",  :limit=>255
    t.boolean  "saved_default",         :default=>false
    t.integer  "status",                :limit=>4
    t.integer  "user_id",               :limit=>4, :index=>{:name=>"index_contacts_on_user_id", :using=>:btree}
    t.text     "special_fields",        :limit=>65535
    t.text     "domains",               :limit=>65535
    t.string   "country_code",          :limit=>255
    t.string   "workflow_state",        :limit=>255
    t.boolean  "phone_number_approved", :default=>false
  end
  add_index "contacts", ["id", "parent_id"], :name=>"index_contacts_on_id_and_parent_id", :using=>:btree
  add_index "contacts", ["id", "type"], :name=>"index_contacts_on_id_and_type", :using=>:btree

  create_table "countries", force: :cascade do |t|
    t.string  "iso1_code", :limit=>255
    t.string  "name_caps", :limit=>255
    t.string  "name",      :limit=>255
    t.string  "iso3_code", :limit=>255
    t.integer "num_code",  :limit=>4
  end

  create_table "csr_overrides", force: :cascade do |t|
    t.integer  "csr_id",            :limit=>4
    t.string   "common_name",       :limit=>255
    t.string   "organization",      :limit=>255
    t.string   "organization_unit", :limit=>255
    t.string   "address_1",         :limit=>255
    t.string   "address_2",         :limit=>255
    t.string   "address_3",         :limit=>255
    t.string   "po_box",            :limit=>255
    t.string   "state",             :limit=>255
    t.string   "locality",          :limit=>255
    t.string   "postal_code",       :limit=>255
    t.string   "country",           :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "csr_unique_values", force: :cascade do |t|
    t.string   "unique_value", :limit=>255
    t.integer  "csr_id",       :limit=>4, :index=>{:name=>"index_csr_unique_values_on_csr_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "csrs", force: :cascade do |t|
    t.integer  "certificate_content_id",    :limit=>4, :index=>{:name=>"index_csrs_on_certificate_content_id", :using=>:btree}
    t.text     "body",                      :limit=>65535
    t.integer  "duration",                  :limit=>4
    t.string   "common_name",               :limit=>255, :index=>{:name=>"index_csrs_on_common_name", :using=>:btree}
    t.string   "organization",              :limit=>255, :index=>{:name=>"index_csrs_on_organization", :using=>:btree}
    t.string   "organization_unit",         :limit=>255
    t.string   "state",                     :limit=>255
    t.string   "locality",                  :limit=>255
    t.string   "country",                   :limit=>255
    t.string   "email",                     :limit=>255
    t.string   "sig_alg",                   :limit=>255, :index=>{:name=>"index_csrs_on_sig_alg_and_common_name_and_email", :with=>["common_name", "email"], :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names", :limit=>65535
    t.integer  "strength",                  :limit=>4
    t.boolean  "challenge_password"
    t.integer  "certificate_lookup_id",     :limit=>4, :index=>{:name=>"index_csrs_on_certificate_lookup_id", :using=>:btree}
    t.text     "decoded",                   :limit=>65535
    t.string   "ext_customer_ref",          :limit=>255
    t.string   "public_key_sha1",           :limit=>255
    t.string   "public_key_sha256",         :limit=>255
    t.string   "public_key_md5",            :limit=>255
    t.integer  "ssl_account_id",            :limit=>4, :index=>{:name=>"index_csrs_on_ssl_account_id", :using=>:btree}
    t.string   "ref",                       :limit=>255
    t.string   "friendly_name",             :limit=>255
    t.text     "modulus",                   :limit=>65535
  end
  add_index "csrs", ["certificate_content_id", "common_name"], :name=>"index_csrs_on_common_name_and_certificate_content_id", :using=>:btree
  add_index "csrs", ["common_name", "body", "decoded"], :name=>"index_csrs_cn_b_d", :type=>:fulltext
  add_index "csrs", ["common_name", "email", "sig_alg"], :name=>"index_csrs_on_3_cols", :using=>:btree
  add_index "csrs", ["common_name", "email", "sig_alg"], :name=>"index_csrs_on_common_name_and_email_and_sig_alg", :using=>:btree

  create_table "dbs", force: :cascade do |t|
    t.string "name",     :limit=>255
    t.string "host",     :limit=>255
    t.string "username", :limit=>255
    t.string "password", :limit=>255
  end

  create_table "delayed_job_groups", force: :cascade do |t|
    t.text    "on_completion_job",           :limit=>65535
    t.text    "on_completion_job_options",   :limit=>65535
    t.text    "on_cancellation_job",         :limit=>65535
    t.text    "on_cancellation_job_options", :limit=>65535
    t.boolean "queueing_complete",           :default=>false, :null=>false
    t.boolean "blocked",                     :default=>false, :null=>false
    t.boolean "failure_cancels_group",       :default=>true, :null=>false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",     :limit=>4, :default=>0, :index=>{:name=>"index_delayed_jobs_on_priority_and_run_at_and_locked_by", :with=>["run_at", "locked_by"], :using=>:btree}
    t.integer  "attempts",     :limit=>4, :default=>0
    t.text     "handler",      :limit=>4294967295, :null=>false
    t.text     "last_error",   :limit=>4294967295
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",    :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue",        :limit=>255, :index=>{:name=>"delayed_jobs_queue", :using=>:btree}
    t.boolean  "blocked",      :default=>false, :null=>false
    t.integer  "job_group_id", :limit=>4, :index=>{:name=>"index_delayed_jobs_on_job_group_id", :using=>:btree}
  end

  create_table "deposits", force: :cascade do |t|
    t.float    "amount",         :limit=>24
    t.string   "full_name",      :limit=>255
    t.string   "credit_card",    :limit=>255
    t.string   "last_digits",    :limit=>255
    t.string   "payment_method", :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discountables_sellables", force: :cascade do |t|
    t.integer  "discountable_id",   :limit=>4
    t.string   "discountable_type", :limit=>255
    t.integer  "sellable_id",       :limit=>4
    t.string   "sellable_type",     :limit=>255
    t.integer  "amount",            :limit=>4
    t.string   "apply_as",          :limit=>255
    t.string   "status",            :limit=>255
    t.text     "notes",             :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discounts", force: :cascade do |t|
    t.integer  "discountable_id",   :limit=>4
    t.string   "discountable_type", :limit=>255
    t.string   "value",             :limit=>255
    t.string   "apply_as",          :limit=>255
    t.string   "label",             :limit=>255
    t.string   "ref",               :limit=>255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",            :limit=>255
    t.integer  "remaining",         :limit=>4
    t.integer  "benefactor_id",     :limit=>4, :index=>{:name=>"index_discounts_on_benefactor_id_and_benefactor_type", :with=>["benefactor_type"], :using=>:btree}
    t.string   "benefactor_type",   :limit=>255
  end

  create_table "discounts_certificates", force: :cascade do |t|
    t.integer  "discount_id",    :limit=>4
    t.integer  "certificate_id", :limit=>4
    t.datetime "created_at",     :null=>false
    t.datetime "updated_at",     :null=>false
  end

  create_table "discounts_orders", force: :cascade do |t|
    t.integer  "discount_id", :limit=>4, :index=>{:name=>"index_discounts_orders_on_discount_id", :using=>:btree}
    t.integer  "order_id",    :limit=>4, :index=>{:name=>"index_discounts_orders_on_order_id", :using=>:btree}
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end
  add_index "discounts_orders", ["discount_id", "order_id"], :name=>"index_discounts_orders_on_discount_id_and_order_id", :using=>:btree

  create_table "domain_control_validations", force: :cascade do |t|
    t.integer  "csr_id",                     :limit=>4, :index=>{:name=>"index_domain_control_validations_on_csr_id", :using=>:btree}
    t.string   "email_address",              :limit=>255
    t.text     "candidate_addresses",        :limit=>65535
    t.string   "subject",                    :limit=>255, :index=>{:name=>"index_domain_control_validations_on_subject", :using=>:btree}
    t.string   "address_to_find_identifier", :limit=>255
    t.string   "identifier",                 :limit=>255
    t.boolean  "identifier_found"
    t.datetime "responded_at"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "workflow_state",             :limit=>255, :index=>{:name=>"index_domain_control_validations_on_workflow_state", :using=>:btree}
    t.string   "dcv_method",                 :limit=>255
    t.integer  "certificate_name_id",        :limit=>4, :index=>{:name=>"index_domain_control_validations_on_certificate_name_id", :using=>:btree}
    t.string   "failure_action",             :limit=>255
    t.integer  "validation_compliance_id",   :limit=>4, :index=>{:name=>"index_domain_control_validations_on_validation_compliance_id", :using=>:btree}
    t.datetime "validation_compliance_date"
    t.integer  "csr_unique_value_id",        :limit=>4, :index=>{:name=>"index_domain_control_validations_on_csr_unique_value_id", :using=>:btree}
  end
  add_index "domain_control_validations", ["certificate_name_id", "email_address", "dcv_method"], :name=>"index_domain_control_validations_on_3_cols", :using=>:btree
  add_index "domain_control_validations", ["csr_id", "email_address", "dcv_method"], :name=>"index_domain_control_validations_on_3_cols(2)", :using=>:btree
  add_index "domain_control_validations", ["id", "csr_id"], :name=>"index_domain_control_validations_on_id_csr_id", :using=>:btree

  create_table "duo_accounts", force: :cascade do |t|
    t.integer  "ssl_account_id",              :limit=>4, :index=>{:name=>"index_duo_accounts_on_ssl_account_id", :using=>:btree}
    t.string   "duo_ikey",                    :limit=>255
    t.string   "duo_skey",                    :limit=>255
    t.string   "duo_akey",                    :limit=>255
    t.string   "duo_hostname",                :limit=>255
    t.string   "encrypted_duo_ikey",          :limit=>255
    t.string   "encrypted_duo_skey",          :limit=>255
    t.string   "encrypted_duo_akey",          :limit=>255
    t.string   "encrypted_duo_hostname",      :limit=>255
    t.string   "encrypted_duo_ikey_salt",     :limit=>255
    t.string   "encrypted_duo_ikey_iv",       :limit=>255
    t.string   "encrypted_duo_skey_salt",     :limit=>255
    t.string   "encrypted_duo_skey_iv",       :limit=>255
    t.string   "encrypted_duo_akey_salt",     :limit=>255
    t.string   "encrypted_duo_akey_iv",       :limit=>255
    t.string   "encrypted_duo_hostname_salt", :limit=>255
    t.string   "encrypted_duo_hostname_iv",   :limit=>255
    t.datetime "created_at",                  :null=>false
    t.datetime "updated_at",                  :null=>false
  end

  create_table "duplicate_v2_users", force: :cascade do |t|
    t.string   "login",      :limit=>255
    t.string   "email",      :limit=>255
    t.string   "password",   :limit=>255
    t.integer  "user_id",    :limit=>4, :index=>{:name=>"index_duplicate_v2_users_on_user_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "folders", force: :cascade do |t|
    t.integer  "parent_id",      :limit=>4, :index=>{:name=>"index_folders_on_parent_id", :using=>:btree}
    t.boolean  "default",        :default=>false, :null=>false, :index=>{:name=>"index_folder_statuses", :with=>["archived", "name", "ssl_account_id", "expired", "active", "revoked"], :using=>:btree}
    t.boolean  "archived",       :default=>false, :null=>false, :index=>{:name=>"index_folders_on_archived", :using=>:btree}
    t.string   "name",           :limit=>255, :null=>false, :index=>{:name=>"index_folders_on_name", :using=>:btree}
    t.string   "description",    :limit=>255
    t.integer  "ssl_account_id", :limit=>4, :null=>false, :index=>{:name=>"index_folders_on_ssl_account_id", :using=>:btree}
    t.integer  "items_count",    :limit=>4, :default=>0
    t.datetime "created_at",     :null=>false
    t.datetime "updated_at",     :null=>false
    t.boolean  "expired",        :default=>false, :index=>{:name=>"index_folders_on_expired", :using=>:btree}
    t.boolean  "active",         :default=>false, :index=>{:name=>"index_folders_on_active", :using=>:btree}
    t.boolean  "revoked",        :default=>false, :index=>{:name=>"index_folders_on_revoked", :using=>:btree}
  end
  add_index "folders", ["archived", "name", "ssl_account_id"], :name=>"index_folders_on_archived_and_name_and_ssl_account_id", :using=>:btree
  add_index "folders", ["default", "name", "ssl_account_id"], :name=>"index_folders_on_default_and_name_and_ssl_account_id", :using=>:btree
  add_index "folders", ["name", "ssl_account_id", "active", "revoked"], :name=>"index_folders_on_name_and_ssl_account_id_and_active_and_revoked", :using=>:btree
  add_index "folders", ["name", "ssl_account_id", "expired"], :name=>"index_folders_on_name_and_ssl_account_id_and_expired", :using=>:btree
  add_index "folders", ["name", "ssl_account_id", "revoked"], :name=>"index_folders_on_name_and_ssl_account_id_and_revoked", :using=>:btree

  create_table "funded_accounts", force: :cascade do |t|
    t.integer  "ssl_account_id", :limit=>4, :index=>{:name=>"index_funded_accounts_on_ssl_account_id", :using=>:btree}
    t.integer  "cents",          :limit=>4, :default=>0
    t.string   "state",          :limit=>255
    t.string   "currency",       :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "card_declined",  :limit=>65535
  end

  create_table "gateways", force: :cascade do |t|
    t.string "service",  :limit=>255
    t.string "login",    :limit=>255
    t.string "password", :limit=>255
    t.string "mode",     :limit=>255
  end

  create_table "groupings", force: :cascade do |t|
    t.integer  "ssl_account_id", :limit=>4
    t.string   "type",           :limit=>255
    t.string   "name",           :limit=>255
    t.string   "nav_tool",       :limit=>255
    t.integer  "parent_id",      :limit=>4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",         :limit=>255
  end

  create_table "invoices", force: :cascade do |t|
    t.integer  "order_id",         :limit=>4, :index=>{:name=>"index_invoices_on_order_id", :using=>:btree}
    t.text     "description",      :limit=>65535
    t.string   "company",          :limit=>255
    t.string   "first_name",       :limit=>255
    t.string   "last_name",        :limit=>255
    t.string   "address_1",        :limit=>255
    t.string   "address_2",        :limit=>255
    t.string   "country",          :limit=>255
    t.string   "city",             :limit=>255
    t.string   "state",            :limit=>255
    t.string   "postal_code",      :limit=>255
    t.string   "phone",            :limit=>255
    t.string   "fax",              :limit=>255
    t.string   "vat",              :limit=>255
    t.string   "tax",              :limit=>255
    t.text     "notes",            :limit=>65535
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
    t.string   "type",             :limit=>255
    t.integer  "billable_id",      :limit=>4, :index=>{:name=>"index_invoices_on_billable_id_and_billable_type", :with=>["billable_type"], :using=>:btree}
    t.string   "billable_type",    :limit=>255
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "reference_number", :limit=>255
    t.string   "status",           :limit=>255
    t.string   "default_payment",  :limit=>255
  end
  add_index "invoices", ["id", "type"], :name=>"index_invoices_on_id_and_type", :using=>:btree

  create_table "legacy_v2_user_mappings", force: :cascade do |t|
    t.integer  "old_user_id",        :limit=>4
    t.integer  "user_mappable_id",   :limit=>4
    t.string   "user_mappable_type", :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "order_id",              :limit=>4, :index=>{:name=>"index_line_items_on_order_id", :using=>:btree}
    t.integer "affiliate_id",          :limit=>4, :index=>{:name=>"index_line_items_on_affiliate_id", :using=>:btree}
    t.integer "sellable_id",           :limit=>4, :index=>{:name=>"index_line_items_on_sellable_id", :using=>:btree}
    t.string  "sellable_type",         :limit=>255, :index=>{:name=>"index_line_items_on_sellable_type", :using=>:btree}
    t.integer "cents",                 :limit=>4
    t.string  "currency",              :limit=>255
    t.float   "affiliate_payout_rate", :limit=>24
    t.string  "aff_url",               :limit=>255
    t.integer "qty",                   :limit=>4
  end
  add_index "line_items", ["order_id", "sellable_id", "sellable_type"], :name=>"index_line_items_on_order_id_and_sellable_id_and_sellable_type", :using=>:btree
  add_index "line_items", ["sellable_id", "sellable_type"], :name=>"index_line_items_on_sellable_id_and_sellable_type", :using=>:btree

  create_table "mailboxer_conversations", force: :cascade do |t|
    t.string   "subject",    :limit=>255, :default=>""
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "mailboxer_conversation_opt_outs", force: :cascade do |t|
    t.integer "unsubscriber_id",   :limit=>4, :index=>{:name=>"index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type", :with=>["unsubscriber_type"], :using=>:btree}
    t.string  "unsubscriber_type", :limit=>255
    t.integer "conversation_id",   :limit=>4, :index=>{:name=>"index_mailboxer_conversation_opt_outs_on_conversation_id", :using=>:btree}, :foreign_key=>{:references=>"mailboxer_conversations", :name=>"mb_opt_outs_on_conversations_id", :on_update=>:restrict, :on_delete=>:restrict}
  end

  create_table "mailboxer_notifications", force: :cascade do |t|
    t.string   "type",                 :limit=>255, :index=>{:name=>"index_mailboxer_notifications_on_type", :using=>:btree}
    t.text     "body",                 :limit=>65535
    t.string   "subject",              :limit=>255, :default=>""
    t.integer  "sender_id",            :limit=>4, :index=>{:name=>"index_mailboxer_notifications_on_sender_id_and_sender_type", :with=>["sender_type"], :using=>:btree}
    t.string   "sender_type",          :limit=>255
    t.integer  "conversation_id",      :limit=>4, :index=>{:name=>"index_mailboxer_notifications_on_conversation_id", :using=>:btree}, :foreign_key=>{:references=>"mailboxer_conversations", :name=>"notifications_on_conversation_id", :on_update=>:restrict, :on_delete=>:restrict}
    t.boolean  "draft",                :default=>false
    t.string   "notification_code",    :limit=>255
    t.integer  "notified_object_id",   :limit=>4, :index=>{:name=>"index_mailboxer_notifications_on_notified_object_id_and_type", :with=>["notified_object_type"], :using=>:btree}
    t.string   "notified_object_type", :limit=>255
    t.string   "attachment",           :limit=>255
    t.datetime "updated_at",           :null=>false
    t.datetime "created_at",           :null=>false
    t.boolean  "global",               :default=>false
    t.datetime "expires"
  end

  create_table "mailboxer_receipts", force: :cascade do |t|
    t.integer  "receiver_id",     :limit=>4, :index=>{:name=>"index_mailboxer_receipts_on_receiver_id_and_receiver_type", :with=>["receiver_type"], :using=>:btree}
    t.string   "receiver_type",   :limit=>255
    t.integer  "notification_id", :limit=>4, :null=>false, :index=>{:name=>"index_mailboxer_receipts_on_notification_id", :using=>:btree}, :foreign_key=>{:references=>"mailboxer_notifications", :name=>"receipts_on_notification_id", :on_update=>:restrict, :on_delete=>:restrict}
    t.boolean  "is_read",         :default=>false
    t.boolean  "trashed",         :default=>false
    t.boolean  "deleted",         :default=>false
    t.string   "mailbox_type",    :limit=>25
    t.datetime "created_at",      :null=>false
    t.datetime "updated_at",      :null=>false
    t.boolean  "is_delivered",    :default=>false
    t.string   "delivery_method", :limit=>255
    t.string   "message_id",      :limit=>255
  end

  create_table "malware_hashes", force: :cascade do |t|
    t.string "url", :limit=>32, :null=>false
  end

  create_table "malwares", force: :cascade do |t|
    t.integer  "black_major",   :limit=>4
    t.integer  "black_minor",   :limit=>4
    t.integer  "malware_major", :limit=>4
    t.integer  "malware_minor", :limit=>4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes", force: :cascade do |t|
    t.string   "title",        :limit=>50, :default=>""
    t.text     "note",         :limit=>65535
    t.integer  "notable_id",   :limit=>4, :index=>{:name=>"index_notes_on_notable_id", :using=>:btree}
    t.string   "notable_type", :limit=>255, :index=>{:name=>"index_notes_on_notable_type", :using=>:btree}
    t.integer  "user_id",      :limit=>4, :index=>{:name=>"index_notes_on_user_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "notes", ["notable_id", "notable_type"], :name=>"index_notes_on_notable_id_and_notable_type", :using=>:btree

  create_table "notification_groups", force: :cascade do |t|
    t.integer  "ssl_account_id", :limit=>4, :index=>{:name=>"index_notification_groups_on_ssl_account_id", :using=>:btree}
    t.string   "ref",            :limit=>255, :null=>false
    t.string   "friendly_name",  :limit=>255, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scan_port",      :limit=>255, :default=>"443"
    t.boolean  "notify_all",     :default=>true
    t.boolean  "status"
  end
  add_index "notification_groups", ["ssl_account_id", "ref"], :name=>"index_notification_groups_on_ssl_account_id_and_ref", :using=>:btree

  create_table "notification_groups_contacts", force: :cascade do |t|
    t.string   "email_address",         :limit=>255
    t.integer  "notification_group_id", :limit=>4, :index=>{:name=>"index_notification_groups_contacts_on_notification_group_id", :using=>:btree}
    t.integer  "contactable_id",        :limit=>4
    t.string   "contactable_type",      :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_groups_subjects", force: :cascade do |t|
    t.string   "domain_name",           :limit=>255
    t.integer  "notification_group_id", :limit=>4, :index=>{:name=>"index_notification_groups_subjects_on_notification_group_id", :using=>:btree}
    t.integer  "subjectable_id",        :limit=>4, :index=>{:name=>"index_notification_groups_subjects_on_two_fields", :with=>["subjectable_type"], :using=>:btree}
    t.string   "subjectable_type",      :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_page",          :limit=>255
  end

  create_table "order_transactions", force: :cascade do |t|
    t.integer  "order_id",     :limit=>4, :index=>{:name=>"index_order_transactions_on_order_id", :using=>:btree}
    t.integer  "old_amount",   :limit=>4
    t.boolean  "success"
    t.string   "reference",    :limit=>255
    t.string   "message",      :limit=>255
    t.string   "action",       :limit=>255
    t.text     "params",       :limit=>65535
    t.text     "avs",          :limit=>65535
    t.text     "cvv",          :limit=>65535
    t.string   "fraud_review", :limit=>255
    t.boolean  "test"
    t.string   "notes",        :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cents",        :limit=>4
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "billing_profile_id",     :limit=>4, :index=>{:name=>"index_orders_on_billing_profile_id", :using=>:btree}
    t.integer  "billable_id",            :limit=>4, :index=>{:name=>"index_orders_on_billable_id", :using=>:btree}
    t.string   "billable_type",          :limit=>255, :index=>{:name=>"index_orders_on_billable_type", :using=>:btree}
    t.integer  "address_id",             :limit=>4, :index=>{:name=>"index_orders_on_address_id", :using=>:btree}
    t.integer  "cents",                  :limit=>4
    t.string   "currency",               :limit=>255
    t.datetime "created_at",             :index=>{:name=>"index_orders_on_created_at", :using=>:btree}
    t.datetime "updated_at",             :index=>{:name=>"index_orders_on_updated_at", :using=>:btree}
    t.datetime "paid_at"
    t.datetime "canceled_at"
    t.integer  "lock_version",           :limit=>4, :default=>0
    t.string   "description",            :limit=>255
    t.string   "state",                  :limit=>255, :default=>"pending", :index=>{:name=>"index_orders_on_state_and_billable_id_and_billable_type", :with=>["billable_id", "billable_type"], :using=>:btree}
    t.string   "status",                 :limit=>255, :default=>"active", :index=>{:name=>"index_orders_on_status", :using=>:btree}
    t.string   "reference_number",       :limit=>255, :index=>{:name=>"index_orders_on_reference_number", :using=>:btree}
    t.integer  "deducted_from_id",       :limit=>4, :index=>{:name=>"index_orders_on_deducted_from_id", :using=>:btree}
    t.string   "notes",                  :limit=>255
    t.string   "po_number",              :limit=>255, :index=>{:name=>"index_orders_on_po_number", :using=>:btree}
    t.string   "quote_number",           :limit=>255, :index=>{:name=>"index_orders_on_quote_number", :using=>:btree}
    t.integer  "visitor_token_id",       :limit=>4, :index=>{:name=>"index_orders_on_visitor_token_id", :using=>:btree}
    t.string   "ext_affiliate_name",     :limit=>255
    t.string   "ext_affiliate_id",       :limit=>255
    t.boolean  "ext_affiliate_credited"
    t.string   "ext_customer_ref",       :limit=>255
    t.string   "approval",               :limit=>255
    t.integer  "invoice_id",             :limit=>4, :index=>{:name=>"index_orders_on_invoice_id", :using=>:btree}
    t.string   "type",                   :limit=>255
    t.text     "invoice_description",    :limit=>65535
    t.integer  "cur_wildcard",           :limit=>4
    t.integer  "cur_non_wildcard",       :limit=>4
    t.integer  "max_wildcard",           :limit=>4
    t.integer  "max_non_wildcard",       :limit=>4
    t.integer  "wildcard_cents",         :limit=>4
    t.integer  "non_wildcard_cents",     :limit=>4
    t.integer  "reseller_tier_id",       :limit=>4, :index=>{:name=>"index_orders_on_reseller_tier_id", :using=>:btree}
  end
  add_index "orders", ["billable_id", "billable_type"], :name=>"index_orders_on_billable_id_and_billable_type", :using=>:btree
  add_index "orders", ["id", "state"], :name=>"index_orders_on_id_and_state", :using=>:btree
  add_index "orders", ["id", "type"], :name=>"index_orders_on_id_and_type", :using=>:btree
  add_index "orders", ["state", "description", "notes"], :name=>"index_orders_on_state_and_description_and_notes", :using=>:btree

  create_table "other_party_requests", force: :cascade do |t|
    t.integer  "other_party_requestable_id",   :limit=>4
    t.string   "other_party_requestable_type", :limit=>255
    t.integer  "user_id",                      :limit=>4, :index=>{:name=>"index_other_party_requests_on_user_id", :using=>:btree}
    t.text     "email_addresses",              :limit=>65535
    t.string   "identifier",                   :limit=>255
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "order_id",     :limit=>4, :index=>{:name=>"index_payments_on_order_id", :using=>:btree}
    t.integer  "address_id",   :limit=>4, :index=>{:name=>"index_payments_on_address_id", :using=>:btree}
    t.integer  "cents",        :limit=>4
    t.string   "currency",     :limit=>255
    t.string   "confirmation", :limit=>255
    t.datetime "cleared_at",   :index=>{:name=>"index_payments_on_cleared_at", :using=>:btree}
    t.datetime "voided_at"
    t.datetime "created_at",   :index=>{:name=>"index_payments_on_created_at", :using=>:btree}
    t.datetime "updated_at",   :index=>{:name=>"index_payments_on_updated_at", :using=>:btree}
    t.integer  "lock_version", :limit=>4, :default=>0
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name",          :limit=>255
    t.string   "action",        :limit=>255
    t.string   "subject_class", :limit=>255
    t.integer  "subject_id",    :limit=>4
    t.text     "description",   :limit=>65535
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

  create_table "permissions_roles", force: :cascade do |t|
    t.integer  "permission_id", :limit=>4, :index=>{:name=>"index_permissions_roles_on_permission_id", :using=>:btree}
    t.integer  "role_id",       :limit=>4, :index=>{:name=>"index_permissions_roles_on_role_id", :using=>:btree}
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end
  add_index "permissions_roles", ["permission_id", "role_id"], :name=>"index_permissions_roles_on_permission_id_and_role_id", :using=>:btree

  create_table "physical_tokens", force: :cascade do |t|
    t.integer  "certificate_order_id",  :limit=>4, :index=>{:name=>"index_physical_tokens_on_certificate_order_id", :using=>:btree}
    t.integer  "signed_certificate_id", :limit=>4, :index=>{:name=>"index_physical_tokens_on_signed_certificate_id", :using=>:btree}
    t.string   "tracking_number",       :limit=>255
    t.string   "shipping_method",       :limit=>255
    t.string   "activation_pin",        :limit=>255
    t.string   "manufacturer",          :limit=>255
    t.string   "model_number",          :limit=>255
    t.string   "serial_number",         :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes",                 :limit=>65535
    t.string   "name",                  :limit=>255
    t.string   "workflow_state",        :limit=>255
    t.string   "admin_pin",             :limit=>255
    t.string   "license",               :limit=>255
    t.string   "management_key",        :limit=>255
  end

  create_table "preferences", force: :cascade do |t|
    t.string   "name",       :limit=>255, :null=>false
    t.integer  "owner_id",   :limit=>4, :null=>false
    t.string   "owner_type", :limit=>255, :null=>false, :index=>{:name=>"index_preferences_on_owner_type_and_owner_id", :with=>["owner_id"], :using=>:btree}
    t.integer  "group_id",   :limit=>4, :index=>{:name=>"index_preferences_on_owner_and_name_and_preference", :with=>["group_type", "name", "owner_id", "owner_type"], :unique=>true, :using=>:btree}
    t.string   "group_type", :limit=>255
    t.string   "value",      :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "preferences", ["group_id", "group_type", "owner_id", "owner_type", "value"], :name=>"index_preferences_on_5_cols", :using=>:btree
  add_index "preferences", ["group_id", "group_type"], :name=>"index_preferences_on_group_id_and_group_type", :using=>:btree
  add_index "preferences", ["id", "name", "owner_id", "owner_type", "value"], :name=>"index_preferences_on_owner_and_name_and_value", :using=>:btree
  add_index "preferences", ["id", "name", "value"], :name=>"index_preferences_on_name_and_value", :using=>:btree
  add_index "preferences", ["id", "owner_id", "owner_type"], :name=>"index_preferences_on_id_and_owner_id_and_owner_type", :unique=>true, :using=>:btree
  add_index "preferences", ["id", "owner_id", "owner_type"], :name=>"index_preferences_on_owner_id_and_owner_type", :unique=>true, :using=>:btree

  create_table "product_variant_groups", force: :cascade do |t|
    t.integer  "variantable_id",        :limit=>4
    t.string   "variantable_type",      :limit=>255
    t.string   "title",                 :limit=>255
    t.string   "status",                :limit=>255
    t.text     "description",           :limit=>65535
    t.text     "text_only_description", :limit=>65535
    t.integer  "display_order",         :limit=>4
    t.string   "serial",                :limit=>255
    t.string   "published_as",          :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_variant_items", force: :cascade do |t|
    t.integer  "product_variant_group_id", :limit=>4, :index=>{:name=>"index_product_variant_items_on_product_variant_group_id", :using=>:btree}
    t.string   "title",                    :limit=>255
    t.string   "status",                   :limit=>255
    t.text     "description",              :limit=>65535
    t.text     "text_only_description",    :limit=>65535
    t.integer  "amount",                   :limit=>4
    t.integer  "display_order",            :limit=>4
    t.string   "item_type",                :limit=>255
    t.string   "value",                    :limit=>255
    t.string   "serial",                   :limit=>255
    t.string   "published_as",             :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer  "order_id",                 :limit=>4, :index=>{:name=>"index_receipts_on_order_id", :using=>:btree}
    t.string   "confirmation_recipients",  :limit=>255
    t.string   "receipt_recipients",       :limit=>255
    t.string   "processed_recipients",     :limit=>255
    t.string   "deposit_reference_number", :limit=>255
    t.string   "deposit_created_at",       :limit=>255
    t.string   "deposit_description",      :limit=>255
    t.string   "deposit_method",           :limit=>255
    t.string   "profile_full_name",        :limit=>255
    t.string   "profile_credit_card",      :limit=>255
    t.string   "profile_last_digits",      :limit=>255
    t.string   "deposit_amount",           :limit=>255
    t.string   "available_funds",          :limit=>255
    t.string   "order_reference_number",   :limit=>255
    t.string   "order_created_at",         :limit=>255
    t.string   "line_item_descriptions",   :limit=>255
    t.string   "line_item_amounts",        :limit=>255
    t.string   "order_amount",             :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "refunds", force: :cascade do |t|
    t.string   "merchant",             :limit=>255
    t.string   "reference",            :limit=>255
    t.integer  "amount",               :limit=>4
    t.string   "status",               :limit=>255
    t.integer  "user_id",              :limit=>4, :index=>{:name=>"index_refunds_on_user_id", :using=>:btree}
    t.integer  "order_id",             :limit=>4, :index=>{:name=>"index_refunds_on_order_id", :using=>:btree}
    t.integer  "order_transaction_id", :limit=>4, :index=>{:name=>"index_refunds_on_order_transaction_id", :using=>:btree}
    t.string   "reason",               :limit=>255
    t.boolean  "partial_refund",       :default=>false
    t.string   "message",              :limit=>255
    t.text     "merchant_response",    :limit=>65535
    t.boolean  "test"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registered_agents", force: :cascade do |t|
    t.string   "ref",             :limit=>255, :null=>false
    t.integer  "ssl_account_id",  :limit=>4, :null=>false, :index=>{:name=>"index_registered_agents_on_ssl_account_id", :using=>:btree}
    t.string   "ip_address",      :limit=>255, :null=>false
    t.string   "mac_address",     :limit=>255, :null=>false
    t.string   "agent",           :limit=>255, :null=>false
    t.string   "friendly_name",   :limit=>255
    t.integer  "requester_id",    :limit=>4, :index=>{:name=>"index_registered_agents_on_requester_id", :using=>:btree}
    t.datetime "requested_at"
    t.integer  "approver_id",     :limit=>4, :index=>{:name=>"index_registered_agents_on_approver_id", :using=>:btree}
    t.datetime "approved_at"
    t.string   "workflow_status", :limit=>255, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reminder_triggers", force: :cascade do |t|
    t.integer  "name",       :limit=>4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "renewal_attempts", force: :cascade do |t|
    t.integer  "certificate_order_id", :limit=>4, :index=>{:name=>"index_renewal_attempts_on_certificate_order_id", :using=>:btree}
    t.integer  "order_transaction_id", :limit=>4, :index=>{:name=>"index_renewal_attempts_on_order_transaction_id", :using=>:btree}
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "renewal_notifications", force: :cascade do |t|
    t.integer  "certificate_order_id", :limit=>4, :index=>{:name=>"index_renewal_notifications_on_certificate_order_id", :using=>:btree}
    t.text     "body",                 :limit=>65535
    t.string   "recipients",           :limit=>255
    t.string   "subject",              :limit=>255
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "reseller_tiers", force: :cascade do |t|
    t.string   "label",        :limit=>255
    t.string   "description",  :limit=>255
    t.integer  "amount",       :limit=>4
    t.string   "roles",        :limit=>255
    t.string   "published_as", :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resellers", force: :cascade do |t|
    t.integer  "ssl_account_id",    :limit=>4, :index=>{:name=>"index_resellers_on_ssl_account_id", :using=>:btree}
    t.integer  "reseller_tier_id",  :limit=>4, :index=>{:name=>"index_resellers_on_reseller_tier_id", :using=>:btree}
    t.string   "first_name",        :limit=>255
    t.string   "last_name",         :limit=>255
    t.string   "email",             :limit=>255
    t.string   "phone",             :limit=>255
    t.string   "organization",      :limit=>255
    t.string   "address1",          :limit=>255
    t.string   "address2",          :limit=>255
    t.string   "address3",          :limit=>255
    t.string   "po_box",            :limit=>255
    t.string   "postal_code",       :limit=>255
    t.string   "city",              :limit=>255
    t.string   "state",             :limit=>255
    t.string   "country",           :limit=>255
    t.string   "ext",               :limit=>255
    t.string   "fax",               :limit=>255
    t.string   "website",           :limit=>255
    t.string   "tax_number",        :limit=>255
    t.string   "roles",             :limit=>255
    t.string   "type_organization", :limit=>255
    t.string   "workflow_state",    :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "revocation_notifications", force: :cascade do |t|
    t.string "email",        :limit=>255
    t.text   "fingerprints", :limit=>65535
    t.string "status",       :limit=>255
  end

  create_table "revocations", force: :cascade do |t|
    t.string   "fingerprint",                       :limit=>255, :index=>{:name=>"index_revocations_on_fingerprint", :using=>:btree}
    t.string   "replacement_fingerprint",           :limit=>255, :index=>{:name=>"index_revocations_on_replacement_fingerprint", :using=>:btree}
    t.integer  "revoked_signed_certificate_id",     :limit=>4, :index=>{:name=>"index_revocations_on_revoked_signed_certificate_id", :using=>:btree}
    t.integer  "replacement_signed_certificate_id", :limit=>4, :index=>{:name=>"index_revocations_on_replacement_signed_certificate_id", :using=>:btree}
    t.string   "status",                            :limit=>255
    t.text     "message_before_revoked",            :limit=>65535
    t.text     "message_after_revoked",             :limit=>65535
    t.datetime "revoked_on"
    t.datetime "created_at",                        :null=>false
    t.datetime "updated_at",                        :null=>false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",           :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ssl_account_id", :limit=>4, :index=>{:name=>"index_roles_on_ssl_account_id", :using=>:btree}
    t.text     "description",    :limit=>65535
    t.string   "status",         :limit=>255
  end

  create_table "scan_logs", force: :cascade do |t|
    t.integer  "notification_group_id",  :limit=>4, :index=>{:name=>"index_scan_logs_on_notification_group_id", :using=>:btree}
    t.integer  "scanned_certificate_id", :limit=>4, :index=>{:name=>"index_scan_logs_on_scanned_certificate_id", :using=>:btree}
    t.string   "domain_name",            :limit=>255
    t.string   "scan_status",            :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expiration_date"
    t.integer  "scan_group",             :limit=>4
  end

  create_table "scanned_certificates", force: :cascade do |t|
    t.text     "body",       :limit=>65535
    t.text     "decoded",    :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "serial",     :limit=>255
  end

  create_table "schedules", force: :cascade do |t|
    t.integer  "notification_group_id", :limit=>4, :index=>{:name=>"index_schedules_on_notification_group_id", :using=>:btree}
    t.string   "schedule_type",         :limit=>255, :null=>false
    t.string   "schedule_value",        :limit=>255, :default=>"2", :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sent_reminders", force: :cascade do |t|
    t.text     "body",          :limit=>65535
    t.string   "recipients",    :limit=>255, :index=>{:name=>"index_contacts_on_recipients_subject_trigger_value_expires_at", :with=>["subject", "trigger_value", "expires_at"], :using=>:btree}
    t.string   "subject",       :limit=>255
    t.string   "trigger_value", :limit=>255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reminder_type", :limit=>255
  end

  create_table "server_softwares", force: :cascade do |t|
    t.string   "title",       :limit=>255, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "support_url", :limit=>255
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", :limit=>191, :null=>false, :index=>{:name=>"index_sessions_on_session_id", :using=>:btree}
    t.text     "data",       :limit=>65535
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false, :index=>{:name=>"index_sessions_on_updated_at", :using=>:btree}
  end

  create_table "shopping_carts", force: :cascade do |t|
    t.integer  "user_id",          :limit=>4, :index=>{:name=>"index_shopping_carts_on_user_id", :using=>:btree}
    t.string   "guid",             :limit=>255, :index=>{:name=>"index_shopping_carts_on_guid", :using=>:btree}
    t.text     "content",          :limit=>65535
    t.string   "token",            :limit=>255
    t.string   "crypted_password", :limit=>255
    t.string   "password_salt",    :limit=>255
    t.string   "access",           :limit=>255
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
  end

  create_table "signed_certificates", force: :cascade do |t|
    t.integer  "csr_id",                    :limit=>4, :index=>{:name=>"index_signed_certificates_on_csr_id", :using=>:btree}
    t.integer  "parent_id",                 :limit=>4, :index=>{:name=>"index_signed_certificates_on_parent_id", :using=>:btree}
    t.string   "common_name",               :limit=>255, :index=>{:name=>"index_signed_certificates_on_common_name", :using=>:btree}
    t.string   "organization",              :limit=>255
    t.text     "organization_unit",         :limit=>65535
    t.string   "address1",                  :limit=>255
    t.string   "address2",                  :limit=>255
    t.string   "locality",                  :limit=>255
    t.string   "state",                     :limit=>255
    t.string   "postal_code",               :limit=>255
    t.string   "country",                   :limit=>255
    t.datetime "effective_date"
    t.datetime "expiration_date"
    t.string   "fingerprintSHA",            :limit=>255
    t.string   "fingerprint",               :limit=>255, :index=>{:name=>"index_signed_certificates_on_fingerprint", :using=>:btree}
    t.text     "signature",                 :limit=>65535
    t.string   "url",                       :limit=>255
    t.text     "body",                      :limit=>65535
    t.boolean  "parent_cert"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names", :limit=>65535
    t.integer  "strength",                  :limit=>4, :index=>{:name=>"index_signed_certificates_on_strength", :using=>:btree}
    t.integer  "certificate_lookup_id",     :limit=>4, :index=>{:name=>"index_signed_certificates_on_certificate_lookup_id", :using=>:btree}
    t.text     "decoded",                   :limit=>65535
    t.text     "serial",                    :limit=>65535, :null=>false
    t.string   "ext_customer_ref",          :limit=>255
    t.text     "status",                    :limit=>65535, :null=>false
    t.integer  "ca_id",                     :limit=>4, :index=>{:name=>"index_signed_certificates_on_ca_id", :using=>:btree}, :foreign_key=>{:references=>"cas", :name=>"fk_rails_d21ca532b7", :on_update=>:restrict, :on_delete=>:restrict}
    t.datetime "revoked_at"
    t.string   "type",                      :limit=>255, :index=>{:name=>"index_signed_certificates_t_cci", :with=>["certificate_content_id"], :using=>:btree}
    t.integer  "registered_agent_id",       :limit=>4, :index=>{:name=>"index_signed_certificates_on_registered_agent_id", :using=>:btree}
    t.string   "ejbca_username",            :limit=>255, :index=>{:name=>"index_signed_certificates_on_ejbca_username", :using=>:btree}
    t.integer  "certificate_content_id",    :limit=>4, :index=>{:name=>"index_signed_certificates_on_certificate_content_id", :using=>:btree}, :foreign_key=>{:references=>"certificate_contents", :name=>"fk_signed_certificates_certificate_content_id", :on_update=>:restrict, :on_delete=>:restrict}
  end
  add_index "signed_certificates", ["common_name", "strength"], :name=>"index_signed_certificates_on_3_cols", :using=>:btree
  add_index "signed_certificates", ["common_name", "url", "body", "decoded", "ext_customer_ref", "ejbca_username"], :name=>"index_signed_certificates_cn_u_b_d_ecf_eu", :type=>:fulltext
  add_index "signed_certificates", ["csr_id", "type"], :name=>"index_signed_certificates_on_csr_id_and_type", :using=>:btree
  add_index "signed_certificates", ["id", "type"], :name=>"index_signed_certificates_on_id_and_type", :using=>:btree

  create_table "site_checks", force: :cascade do |t|
    t.text     "url",                   :limit=>65535
    t.integer  "certificate_lookup_id", :limit=>4, :index=>{:name=>"index_site_checks_on_certificate_lookup_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_seals", force: :cascade do |t|
    t.string   "workflow_state", :limit=>255, :index=>{:name=>"index_site_seals_workflow_state", :using=>:btree}
    t.string   "seal_type",      :limit=>255
    t.string   "ref",            :limit=>255, :index=>{:name=>"index_site_seals_ref", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ssl_account_users", force: :cascade do |t|
    t.integer  "user_id",        :limit=>4, :null=>false, :index=>{:name=>"index_ssl_account_users_on_user_id", :using=>:btree}
    t.integer  "ssl_account_id", :limit=>4, :null=>false, :index=>{:name=>"index_ssl_account_users_on_ssl_account_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "approved",       :default=>false
    t.string   "approval_token", :limit=>255
    t.datetime "token_expires"
    t.boolean  "user_enabled",   :default=>true
    t.datetime "invited_at"
    t.datetime "declined_at"
  end
  add_index "ssl_account_users", ["ssl_account_id", "user_id"], :name=>"index_ssl_account_users_on_ssl_account_id_and_user_id", :using=>:btree
  add_index "ssl_account_users", ["user_id", "ssl_account_id", "approved", "user_enabled"], :name=>"index_ssl_account_users_on_four_fields", :using=>:btree

  create_table "ssl_accounts", force: :cascade do |t|
    t.string   "acct_number",            :limit=>255, :index=>{:name=>"index_ssl_account_on_acct_number", :using=>:btree}
    t.string   "roles",                  :limit=>255, :default=>"--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                 :limit=>255
    t.string   "ssl_slug",               :limit=>255, :index=>{:name=>"index_ssl_accounts_on_ssl_slug_and_acct_number", :with=>["acct_number"], :using=>:btree}
    t.string   "company_name",           :limit=>255
    t.string   "issue_dv_no_validation", :limit=>255
    t.string   "billing_method",         :limit=>255, :default=>"monthly"
    t.boolean  "duo_enabled"
    t.boolean  "duo_own_used"
    t.string   "sec_type",               :limit=>255
    t.integer  "default_folder_id",      :limit=>4
    t.boolean  "no_limit",               :default=>false
    t.datetime "epki_agreement"
    t.string   "workflow_state",         :limit=>255, :default=>"active"
  end
  add_index "ssl_accounts", ["acct_number", "company_name", "ssl_slug"], :name=>"index_ssl_accounts_an_cn_ss", :type=>:fulltext
  add_index "ssl_accounts", ["acct_number", "company_name", "ssl_slug"], :name=>"index_ssl_accounts_on_acct_number_and_company_name_and_ssl_slug", :using=>:btree
  add_index "ssl_accounts", ["id", "created_at"], :name=>"index_ssl_accounts_on_id_and_created_at", :using=>:btree

  create_table "ssl_docs", force: :cascade do |t|
    t.integer  "folder_id",             :limit=>4
    t.string   "reviewer",              :limit=>255
    t.string   "notes",                 :limit=>255
    t.string   "admin_notes",           :limit=>255
    t.string   "document_file_name",    :limit=>255
    t.string   "document_file_size",    :limit=>255
    t.string   "document_content_type", :limit=>255
    t.datetime "document_updated_at"
    t.string   "random_secret",         :limit=>255
    t.boolean  "processing"
    t.string   "status",                :limit=>255
    t.string   "display_name",          :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_order_items", force: :cascade do |t|
    t.integer  "sub_itemable_id",         :limit=>4, :index=>{:name=>"index_sub_order_items_on_sub_itemable_id_and_sub_itemable_type", :with=>["sub_itemable_type"], :using=>:btree}
    t.string   "sub_itemable_type",       :limit=>255
    t.integer  "product_variant_item_id", :limit=>4, :index=>{:name=>"index_sub_order_items_on_product_variant_item_id", :using=>:btree}
    t.integer  "quantity",                :limit=>4
    t.integer  "amount",                  :limit=>4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_id",              :limit=>4, :index=>{:name=>"index_sub_order_items_on_product_id", :using=>:btree}
  end
  add_index "sub_order_items", ["id", "sub_itemable_id", "sub_itemable_type"], :name=>"index_sub_order_items_on_sub_itemable", :using=>:btree

  create_table "surl_blacklists", force: :cascade do |t|
    t.string   "fingerprint", :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surl_visits", force: :cascade do |t|
    t.integer  "surl_id",          :limit=>4, :index=>{:name=>"index_surl_visits_on_surl_id", :using=>:btree}
    t.integer  "visitor_token_id", :limit=>4, :index=>{:name=>"index_surl_visits_on_visitor_token_id", :using=>:btree}
    t.string   "referer_host",     :limit=>255
    t.string   "referer_address",  :limit=>255
    t.string   "request_uri",      :limit=>255
    t.string   "http_user_agent",  :limit=>255
    t.string   "result",           :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surls", force: :cascade do |t|
    t.integer  "user_id",       :limit=>4, :index=>{:name=>"index_surls_on_user_id", :using=>:btree}
    t.text     "original",      :limit=>65535
    t.string   "identifier",    :limit=>255
    t.string   "guid",          :limit=>255
    t.string   "username",      :limit=>255
    t.string   "password_hash", :limit=>255
    t.string   "password_salt", :limit=>255
    t.boolean  "require_ssl"
    t.boolean  "share"
    t.string   "status",        :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "system_audits", force: :cascade do |t|
    t.integer  "owner_id",    :limit=>4, :index=>{:name=>"index_system_audits_on_owner_id_and_owner_type", :with=>["owner_type"], :using=>:btree}
    t.string   "owner_type",  :limit=>255
    t.integer  "target_id",   :limit=>4, :index=>{:name=>"index_system_audits_on_4_cols", :with=>["target_type", "owner_id", "owner_type"], :using=>:btree}
    t.string   "target_type", :limit=>255
    t.text     "notes",       :limit=>65535
    t.string   "action",      :limit=>255
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end
  add_index "system_audits", ["target_id", "target_type"], :name=>"index_system_audits_on_target_id_and_target_type", :using=>:btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        :limit=>4, :null=>false, :index=>{:name=>"index_taggings_on_tag_id", :using=>:btree}
    t.integer  "taggable_id",   :limit=>4, :null=>false, :index=>{:name=>"index_taggings_on_taggable_id_and_taggable_type", :with=>["taggable_type"], :using=>:btree}
    t.string   "taggable_type", :limit=>255, :null=>false, :index=>{:name=>"unique_taggings", :with=>["taggable_id", "tag_id"], :unique=>true, :using=>:btree}
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end
  add_index "taggings", ["taggable_type", "taggable_id"], :name=>"index_taggings_on_taggable_type_and_taggable_id", :using=>:btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",           :limit=>255, :null=>false
    t.integer  "ssl_account_id", :limit=>4, :null=>false, :index=>{:name=>"index_tags_on_ssl_account_id", :using=>:btree}
    t.integer  "taggings_count", :limit=>4, :default=>0, :null=>false, :index=>{:name=>"index_tags_on_taggings_count", :using=>:btree}
    t.datetime "created_at",     :null=>false
    t.datetime "updated_at",     :null=>false
  end
  add_index "tags", ["ssl_account_id", "name"], :name=>"index_tags_on_ssl_account_id_and_name", :using=>:btree

  create_table "tracked_urls", force: :cascade do |t|
    t.text     "url",        :limit=>65535
    t.string   "md5",        :limit=>255, :index=>{:name=>"index_tracked_urls_on_md5", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "tracked_urls", ["md5", "url"], :name=>"index_tracked_urls_on_md5_and_url", :length=>{"md5"=>100, "url"=>100}, :using=>:btree

  create_table "trackings", force: :cascade do |t|
    t.integer  "tracked_url_id",   :limit=>4, :index=>{:name=>"index_trackings_on_tracked_url_id", :using=>:btree}
    t.integer  "visitor_token_id", :limit=>4, :index=>{:name=>"index_trackings_on_visitor_token_id", :using=>:btree}
    t.integer  "referer_id",       :limit=>4, :index=>{:name=>"index_trackings_on_referer_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip",        :limit=>255
  end

  create_table "u2fs", force: :cascade do |t|
    t.integer  "user_id",     :limit=>4, :index=>{:name=>"index_u2fs_on_user_id", :using=>:btree}
    t.text     "certificate", :limit=>65535
    t.string   "key_handle",  :limit=>255
    t.string   "public_key",  :limit=>255
    t.integer  "counter",     :limit=>4, :default=>0, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "nick_name",   :limit=>255
  end

  create_table "unsubscribes", force: :cascade do |t|
    t.string   "specs",      :limit=>255
    t.text     "domain",     :limit=>65535
    t.text     "email",      :limit=>65535
    t.text     "ref",        :limit=>65535
    t.boolean  "enforce"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "url_callbacks", force: :cascade do |t|
    t.integer  "callbackable_id",   :limit=>4, :index=>{:name=>"index_url_callbacks_on_callbackable_id_and_callbackable_type", :with=>["callbackable_type"], :using=>:btree}
    t.string   "callbackable_type", :limit=>255
    t.string   "url",               :limit=>255
    t.string   "method",            :limit=>255
    t.text     "auth",              :limit=>65535
    t.text     "headers",           :limit=>65535
    t.text     "parameters",        :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_groups", force: :cascade do |t|
    t.integer "ssl_account_id", :limit=>4, :index=>{:name=>"index_user_groups_on_ssl_account_id", :using=>:btree}
    t.string  "roles",          :limit=>255, :default=>"--- []"
    t.string  "name",           :limit=>255
    t.text    "description",    :limit=>65535
    t.text    "notes",          :limit=>65535
  end

  create_table "user_groups_users", force: :cascade do |t|
    t.integer  "user_id",       :limit=>4, :index=>{:name=>"index_user_groups_users_on_user_id", :using=>:btree}
    t.integer  "user_group_id", :limit=>4, :index=>{:name=>"index_user_groups_users_on_user_group_id", :using=>:btree}
    t.string   "status",        :limit=>255
    t.string   "notes",         :limit=>255
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end
  add_index "user_groups_users", ["user_group_id", "user_id"], :name=>"index_user_groups_users_on_user_group_id_and_user_id", :using=>:btree

  create_table "users", force: :cascade do |t|
    t.integer  "ssl_account_id",      :limit=>4, :index=>{:name=>"index_users_on_ssl_acount_id", :using=>:btree}
    t.string   "login",               :limit=>255, :null=>false, :index=>{:name=>"index_users_on_login", :using=>:btree}
    t.string   "email",               :limit=>255, :null=>false, :index=>{:name=>"index_users_on_email", :using=>:btree}
    t.string   "crypted_password",    :limit=>255
    t.string   "password_salt",       :limit=>255
    t.string   "persistence_token",   :limit=>255, :null=>false
    t.string   "single_access_token", :limit=>255, :null=>false
    t.string   "perishable_token",    :limit=>255, :null=>false, :index=>{:name=>"index_users_on_perishable_token", :using=>:btree}
    t.string   "status",              :limit=>255, :index=>{:name=>"index_users_on_status_and_login_and_email", :with=>["login", "email"], :using=>:btree}
    t.integer  "login_count",         :limit=>4, :default=>0, :null=>false
    t.integer  "failed_login_count",  :limit=>4, :default=>0, :null=>false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip",    :limit=>255
    t.string   "last_login_ip",       :limit=>255
    t.boolean  "active",              :default=>false, :null=>false
    t.string   "openid_identifier",   :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",          :limit=>255
    t.string   "last_name",           :limit=>255
    t.string   "phone",               :limit=>255
    t.string   "organization",        :limit=>255
    t.string   "address1",            :limit=>255
    t.string   "address2",            :limit=>255
    t.string   "address3",            :limit=>255
    t.string   "po_box",              :limit=>255
    t.string   "postal_code",         :limit=>255
    t.string   "city",                :limit=>255
    t.string   "state",               :limit=>255
    t.string   "country",             :limit=>255
    t.boolean  "is_auth_token"
    t.integer  "default_ssl_account", :limit=>4, :index=>{:name=>"index_users_on_default_ssl_account", :using=>:btree}
    t.integer  "max_teams",           :limit=>4
    t.integer  "main_ssl_account",    :limit=>4
    t.boolean  "persist_notice",      :default=>false
    t.string   "duo_enabled",         :limit=>255, :default=>"enabled"
    t.string   "avatar_file_name",    :limit=>255
    t.string   "avatar_content_type", :limit=>255
    t.integer  "avatar_file_size",    :limit=>4
    t.datetime "avatar_updated_at"
  end
  add_index "users", ["id", "ssl_account_id", "status"], :name=>"index_users_on_status_and_ssl_account_id", :using=>:btree
  add_index "users", ["id", "status"], :name=>"index_users_on_status", :using=>:btree
  add_index "users", ["login", "email"], :name=>"index_users_l_e", :type=>:fulltext
  add_index "users", ["login", "email"], :name=>"index_users_on_login_and_email", :using=>:btree
  add_index "users", ["ssl_account_id", "login", "email"], :name=>"index_users_on_ssl_account_id_and_login_and_email", :using=>:btree

  create_table "v2_migration_progresses", force: :cascade do |t|
    t.string   "source_table_name", :limit=>255
    t.integer  "source_id",         :limit=>4
    t.integer  "migratable_id",     :limit=>4
    t.string   "migratable_type",   :limit=>255
    t.datetime "migrated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_compliances", force: :cascade do |t|
    t.string   "document",    :limit=>255
    t.string   "version",     :limit=>255
    t.string   "section",     :limit=>255
    t.string   "description", :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_histories", force: :cascade do |t|
    t.integer  "validation_id",                 :limit=>4, :index=>{:name=>"index_validation_histories_on_validation_id", :using=>:btree}
    t.string   "reviewer",                      :limit=>255
    t.string   "notes",                         :limit=>255
    t.string   "admin_notes",                   :limit=>255
    t.string   "document_file_name",            :limit=>255
    t.string   "document_file_size",            :limit=>255
    t.string   "document_content_type",         :limit=>255
    t.datetime "document_updated_at"
    t.string   "random_secret",                 :limit=>255
    t.boolean  "publish_to_site_seal"
    t.boolean  "publish_to_site_seal_approval", :default=>false
    t.string   "satisfies_validation_methods",  :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "validation_histories", ["validation_id"], :name=>"index_validation_histories_validation_id", :using=>:btree

  create_table "validation_history_validations", force: :cascade do |t|
    t.integer  "validation_history_id", :limit=>4, :index=>{:name=>"index_validation_history_validations_on_validation_history_id", :using=>:btree}
    t.integer  "validation_id",         :limit=>4, :index=>{:name=>"index_validation_history_validations_on_validation_id", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rules", force: :cascade do |t|
    t.string   "description",                          :limit=>255
    t.string   "operator",                             :limit=>255
    t.integer  "parent_id",                            :limit=>4, :index=>{:name=>"index_validation_rules_on_parent_id", :using=>:btree}
    t.text     "applicable_validation_methods",        :limit=>65535
    t.text     "required_validation_methods",          :limit=>65535
    t.string   "required_validation_methods_operator", :limit=>255, :default=>"AND"
    t.text     "notes",                                :limit=>65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rulings", force: :cascade do |t|
    t.integer  "validation_rule_id",      :limit=>4, :index=>{:name=>"index_validation_rulings_on_validation_rule_id", :using=>:btree}
    t.integer  "validation_rulable_id",   :limit=>4, :index=>{:name=>"index_validation_rulings_on_rulable_id_and_rulable_type", :with=>["validation_rulable_type"], :using=>:btree}
    t.string   "validation_rulable_type", :limit=>255
    t.string   "workflow_state",          :limit=>255
    t.string   "status",                  :limit=>255
    t.string   "notes",                   :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rulings_validation_histories", force: :cascade do |t|
    t.integer  "validation_history_id", :limit=>4
    t.integer  "validation_ruling_id",  :limit=>4
    t.string   "status",                :limit=>255
    t.string   "notes",                 :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validations", force: :cascade do |t|
    t.string   "label",          :limit=>255
    t.string   "notes",          :limit=>255
    t.string   "first_name",     :limit=>255
    t.string   "last_name",      :limit=>255
    t.string   "email",          :limit=>255
    t.string   "phone",          :limit=>255
    t.string   "organization",   :limit=>255
    t.string   "address1",       :limit=>255
    t.string   "address2",       :limit=>255
    t.string   "postal_code",    :limit=>255
    t.string   "city",           :limit=>255
    t.string   "state",          :limit=>255
    t.string   "country",        :limit=>255
    t.string   "website",        :limit=>255
    t.string   "contact_email",  :limit=>255
    t.string   "contact_phone",  :limit=>255
    t.string   "tax_number",     :limit=>255
    t.string   "workflow_state", :limit=>255
    t.string   "domain",         :limit=>255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "visitor_tokens", force: :cascade do |t|
    t.integer  "user_id",      :limit=>4, :index=>{:name=>"index_visitor_tokens_on_user_id", :using=>:btree}
    t.integer  "affiliate_id", :limit=>4, :index=>{:name=>"index_visitor_tokens_on_affiliate_id", :using=>:btree}
    t.string   "guid",         :limit=>255, :index=>{:name=>"index_visitor_tokens_on_guid", :using=>:btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "visitor_tokens", ["guid", "affiliate_id"], :name=>"index_visitor_tokens_on_guid_and_affiliate_id", :using=>:btree

  create_table "weak_keys", force: :cascade do |t|
    t.string  "sha1_hash", :limit=>255, :index=>{:name=>"index_weak_keys_on_sha1_hash", :using=>:btree}
    t.string  "algorithm", :limit=>255
    t.integer "size",      :limit=>4
  end

  create_table "websites", force: :cascade do |t|
    t.string  "host",        :limit=>255
    t.string  "api_host",    :limit=>255
    t.string  "name",        :limit=>255
    t.string  "description", :limit=>255
    t.string  "type",        :limit=>255
    t.integer "db_id",       :limit=>4, :index=>{:name=>"index_websites_on_db_id", :using=>:btree}
  end
  add_index "websites", ["id", "type"], :name=>"index_websites_on_id_and_type", :using=>:btree

  create_table "whois_lookups", force: :cascade do |t|
    t.integer  "csr_id",            :limit=>4, :index=>{:name=>"index_whois_lookups_on_csr_id", :using=>:btree}
    t.text     "raw",               :limit=>65535
    t.string   "status",            :limit=>255
    t.datetime "record_created_on"
    t.datetime "expiration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
