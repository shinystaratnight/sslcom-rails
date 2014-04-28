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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131206151716) do

  create_table "addresses", :force => true do |t|
    t.string "name"
    t.string "street1"
    t.string "street2"
    t.string "locality"
    t.string "region"
    t.string "postal_code"
    t.string "country"
    t.string "phone"
  end

  create_table "affiliates", :force => true do |t|
    t.integer  "ssl_account_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "organization"
    t.string   "address1"
    t.string   "address2"
    t.string   "postal_code"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "website"
    t.string   "contact_email"
    t.string   "contact_phone"
    t.string   "tax_number"
    t.string   "payout_method"
    t.string   "payout_threshold"
    t.string   "payout_frequency"
    t.string   "bank_name"
    t.string   "bank_routing_number"
    t.string   "bank_account_number"
    t.string   "swift_code"
    t.string   "checks_payable_to"
    t.string   "epassporte_account"
    t.string   "paypal_account"
    t.string   "type_organization"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "api_credentials", :force => true do |t|
    t.integer  "ssl_account_id"
    t.string   "account_key"
    t.string   "secret_key"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "apis", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "nick_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auto_renewals", :force => true do |t|
    t.integer  "certificate_order_id"
    t.integer  "order_id"
    t.text     "body"
    t.string   "recipients"
    t.string   "subject"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "billing_profiles", :force => true do |t|
    t.integer  "ssl_account_id"
    t.string   "description"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "country"
    t.string   "city"
    t.string   "state"
    t.string   "postal_code"
    t.string   "phone"
    t.string   "company"
    t.string   "credit_card"
    t.string   "card_number"
    t.integer  "expiration_month"
    t.integer  "expiration_year"
    t.string   "security_code"
    t.string   "last_digits"
    t.binary   "data"
    t.binary   "salt"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "billing_profiles", ["ssl_account_id"], :name => "index_billing_profile_on_ssl_account_id"

  create_table "ca_api_requests", :force => true do |t|
    t.integer  "api_requestable_id"
    t.string   "api_requestable_type"
    t.string   "request_url"
    t.text     "parameters"
    t.string   "method"
    t.text     "response"
    t.string   "type"
    t.string   "ca"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificate_api_requests", :force => true do |t|
    t.integer  "server_software_id"
    t.integer  "country_id"
    t.string   "account_key"
    t.string   "secret_key"
    t.boolean  "test"
    t.string   "product"
    t.integer  "period"
    t.integer  "server_count"
    t.string   "other_domains"
    t.string   "common_names_flag"
    t.text     "csr"
    t.string   "organization_name"
    t.string   "post_office_box"
    t.string   "street_address_1"
    t.string   "street_address_2"
    t.string   "street_address_3"
    t.string   "locality_name"
    t.string   "state_or_province_name"
    t.string   "postal_code"
    t.string   "duns_number"
    t.string   "company_number"
    t.string   "registered_locality_name"
    t.string   "registered_state_or_province_name"
    t.string   "registered_country_name"
    t.string   "assumed_name"
    t.string   "business_category"
    t.string   "email_address"
    t.string   "contact_email_address"
    t.string   "dcv_email_address"
    t.string   "ca_certificate_id"
    t.date     "incorporation_date"
    t.boolean  "is_customer_validated"
    t.boolean  "hide_certificate_reference"
    t.string   "external_order_number"
    t.string   "external_order_number_constraint"
    t.string   "response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificate_contents", :force => true do |t|
    t.integer  "certificate_order_id", :null => false
    t.text     "signing_request"
    t.text     "signed_certificate"
    t.integer  "server_software_id"
    t.text     "domains"
    t.integer  "duration"
    t.string   "workflow_state"
    t.boolean  "billing_checkbox"
    t.boolean  "validation_checkbox"
    t.boolean  "technical_checkbox"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificate_contents", ["certificate_order_id"], :name => "index_certificate_contents_on_certificate_order_id"
  add_index "certificate_contents", ["workflow_state"], :name => "index_certificate_contents_on_workflow_state"

  create_table "certificate_lookups", :force => true do |t|
    t.text     "certificate"
    t.string   "serial"
    t.string   "common_name"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
  end

  create_table "certificate_orders", :force => true do |t|
    t.integer  "ssl_account_id"
    t.integer  "validation_id"
    t.integer  "site_seal_id"
    t.string   "workflow_state"
    t.string   "ref"
    t.integer  "num_domains"
    t.integer  "server_licenses"
    t.integer  "line_item_qty"
    t.integer  "amount"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_expired"
    t.integer  "renewal_id"
    t.boolean  "is_test"
    t.string   "auto_renew"
    t.string   "auto_renew_status"
  end

  add_index "certificate_orders", ["created_at"], :name => "index_certificate_orders_on_created_at"
  add_index "certificate_orders", ["is_expired"], :name => "index_certificate_orders_on_is_expired"
  add_index "certificate_orders", ["ref"], :name => "index_certificate_orders_on_ref"
  add_index "certificate_orders", ["site_seal_id"], :name => "index_certificate_orders_site_seal_id"
  add_index "certificate_orders", ["workflow_state"], :name => "index_certificate_orders_on_workflow_state"

  create_table "certificates", :force => true do |t|
    t.integer  "reseller_tier_id"
    t.string   "title"
    t.string   "status"
    t.text     "summary"
    t.text     "text_only_summary"
    t.text     "description"
    t.text     "text_only_description"
    t.boolean  "allow_wildcard_ucc"
    t.string   "published_as",          :limit => 16, :default => "draft"
    t.string   "serial"
    t.string   "product"
    t.string   "icons"
    t.string   "display_order"
    t.string   "roles",                               :default => "--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 40
    t.string   "secret",       :limit => 40
    t.integer  "user_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "contacts", :force => true do |t|
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "department"
    t.string   "po_box"
    t.string   "address1"
    t.string   "address2"
    t.string   "address3"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "postal_code"
    t.string   "email"
    t.string   "phone"
    t.string   "ext"
    t.string   "fax"
    t.string   "notes"
    t.string   "type"
    t.string   "roles",            :default => "--- []"
    t.integer  "contactable_id"
    t.string   "contactable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contacts", ["contactable_id", "contactable_type"], :name => "index_contacts_on_contactable_id_and_contactable_type"

  create_table "countries", :force => true do |t|
    t.string  "iso1_code"
    t.string  "name_caps"
    t.string  "name"
    t.string  "iso3_code"
    t.integer "num_code"
  end

  create_table "csr_overrides", :force => true do |t|
    t.integer  "csr_id"
    t.string   "common_name"
    t.string   "organization"
    t.string   "organization_unit"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "address_3"
    t.string   "po_box"
    t.string   "state"
    t.string   "locality"
    t.string   "postal_code"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "csrs", :force => true do |t|
    t.integer  "certificate_content_id"
    t.text     "body"
    t.integer  "duration"
    t.string   "common_name"
    t.string   "organization"
    t.string   "organization_unit"
    t.string   "state"
    t.string   "locality"
    t.string   "country"
    t.string   "email"
    t.string   "sig_alg"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names"
    t.integer  "strength"
    t.boolean  "challenge_password"
    t.integer  "certificate_lookup_id"
  end

  add_index "csrs", ["certificate_content_id", "common_name"], :name => "index_csrs_on_common_name_and_certificate_content_id"
  add_index "csrs", ["certificate_content_id"], :name => "index_csrs_on_certificate_content_id"
  add_index "csrs", ["common_name"], :name => "index_csrs_on_common_name"
  add_index "csrs", ["organization"], :name => "index_csrs_on_organization"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deposits", :force => true do |t|
    t.float    "amount"
    t.string   "full_name"
    t.string   "credit_card"
    t.string   "last_digits"
    t.string   "payment_method"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discounts", :force => true do |t|
    t.integer  "discountable_id"
    t.string   "discountable_type"
    t.string   "value"
    t.string   "apply_as"
    t.string   "label"
    t.string   "ref"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discounts_certificates", :force => true do |t|
    t.integer  "discount_id"
    t.integer  "certificate_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "discounts_orders", :force => true do |t|
    t.integer  "discount_id"
    t.integer  "order_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "domain_control_validations", :force => true do |t|
    t.integer  "csr_id"
    t.string   "email_address"
    t.text     "candidate_addresses"
    t.string   "subject"
    t.string   "address_to_find_identifier"
    t.string   "identifier"
    t.boolean  "identifier_found"
    t.datetime "responded_at"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "workflow_state"
    t.string   "dcv_method"
  end

  create_table "duplicate_v2_users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "password"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "funded_accounts", :force => true do |t|
    t.integer  "ssl_account_id"
    t.integer  "cents",          :default => 0
    t.string   "state"
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gateways", :force => true do |t|
    t.string "service"
    t.string "login"
    t.string "password"
    t.string "mode"
  end

  create_table "groupings", :force => true do |t|
    t.integer  "ssl_account_id"
    t.string   "type"
    t.string   "name"
    t.string   "nav_tool"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  create_table "legacy_v2_user_mappings", :force => true do |t|
    t.integer  "old_user_id"
    t.integer  "user_mappable_id"
    t.string   "user_mappable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "line_items", :force => true do |t|
    t.integer "order_id"
    t.integer "affiliate_id"
    t.integer "sellable_id"
    t.string  "sellable_type"
    t.integer "cents"
    t.string  "currency"
    t.float   "affiliate_payout_rate"
    t.string  "aff_url"
  end

  add_index "line_items", ["order_id"], :name => "index_line_items_on_order_id"
  add_index "line_items", ["sellable_id", "sellable_type"], :name => "index_line_items_on_sellable_id_and_sellable_type"
  add_index "line_items", ["sellable_id"], :name => "index_line_items_on_sellable_id"
  add_index "line_items", ["sellable_type"], :name => "index_line_items_on_sellable_type"

  create_table "malware_hashes", :force => true do |t|
    t.string "url", :limit => 32, :null => false
  end

  create_table "malwares", :force => true do |t|
    t.integer  "black_major"
    t.integer  "black_minor"
    t.integer  "malware_major"
    t.integer  "malware_minor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes", :force => true do |t|
    t.string   "title",        :limit => 50, :default => ""
    t.text     "note"
    t.integer  "notable_id"
    t.string   "notable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["notable_id"], :name => "index_notes_on_notable_id"
  add_index "notes", ["notable_type"], :name => "index_notes_on_notable_type"
  add_index "notes", ["user_id"], :name => "index_notes_on_user_id"

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 40
    t.string   "secret",                :limit => 40
    t.string   "callback_url"
    t.string   "verifier",              :limit => 20
    t.string   "scope"
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "valid_to"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "order_transactions", :force => true do |t|
    t.integer  "order_id"
    t.integer  "amount"
    t.boolean  "success"
    t.string   "reference"
    t.string   "message"
    t.string   "action"
    t.text     "params"
    t.text     "avs"
    t.text     "cvv"
    t.string   "fraud_review"
    t.boolean  "test"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", :force => true do |t|
    t.integer  "billing_profile_id"
    t.integer  "billable_id"
    t.string   "billable_type"
    t.integer  "address_id"
    t.integer  "cents"
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paid_at"
    t.datetime "canceled_at"
    t.integer  "lock_version",           :default => 0
    t.string   "description"
    t.string   "state",                  :default => "pending"
    t.string   "status",                 :default => "active"
    t.string   "reference_number"
    t.integer  "deducted_from_id"
    t.string   "notes"
    t.string   "po_number"
    t.string   "quote_number"
    t.integer  "visitor_token_id"
    t.string   "ext_affiliate_name"
    t.string   "ext_affiliate_id"
    t.boolean  "ext_affiliate_credited"
  end

  add_index "orders", ["billable_id", "billable_type"], :name => "index_orders_on_billable_id_and_billable_type"
  add_index "orders", ["billable_id"], :name => "index_orders_on_billable_id"
  add_index "orders", ["billable_type"], :name => "index_orders_on_billable_type"
  add_index "orders", ["created_at"], :name => "index_orders_on_created_at"
  add_index "orders", ["po_number"], :name => "index_orders_on_po_number"
  add_index "orders", ["quote_number"], :name => "index_orders_on_quote_number"
  add_index "orders", ["reference_number"], :name => "index_orders_on_reference_number"
  add_index "orders", ["status"], :name => "index_orders_on_status"
  add_index "orders", ["updated_at"], :name => "index_orders_on_updated_at"

  create_table "other_party_requests", :force => true do |t|
    t.integer  "other_party_requestable_id"
    t.string   "other_party_requestable_type"
    t.integer  "user_id"
    t.text     "email_addresses"
    t.string   "identifier"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "order_id"
    t.integer  "address_id"
    t.integer  "cents"
    t.string   "currency"
    t.string   "confirmation"
    t.datetime "cleared_at"
    t.datetime "voided_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", :default => 0
  end

  add_index "payments", ["cleared_at"], :name => "index_payments_on_cleared_at"
  add_index "payments", ["created_at"], :name => "index_payments_on_created_at"
  add_index "payments", ["order_id"], :name => "index_payments_on_order_id"
  add_index "payments", ["updated_at"], :name => "index_payments_on_updated_at"

  create_table "preferences", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "owner_id",   :null => false
    t.string   "owner_type", :null => false
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["group_id", "group_type", "name", "owner_id", "owner_type"], :name => "index_preferences_on_owner_and_name_and_preference", :unique => true
  add_index "preferences", ["owner_id", "owner_type"], :name => "index_preferences_on_owner_id_and_owner_type"

  create_table "product_variant_groups", :force => true do |t|
    t.integer  "variantable_id"
    t.string   "variantable_type"
    t.string   "title"
    t.string   "status"
    t.text     "description"
    t.text     "text_only_description"
    t.integer  "display_order"
    t.string   "serial"
    t.string   "published_as"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_variant_items", :force => true do |t|
    t.integer  "product_variant_group_id"
    t.string   "title"
    t.string   "status"
    t.text     "description"
    t.text     "text_only_description"
    t.integer  "amount"
    t.integer  "display_order"
    t.string   "item_type"
    t.string   "value"
    t.string   "serial"
    t.string   "published_as"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "receipts", :force => true do |t|
    t.integer  "order_id"
    t.string   "confirmation_recipients"
    t.string   "receipt_recipients"
    t.string   "processed_recipients"
    t.string   "deposit_reference_number"
    t.string   "deposit_created_at"
    t.string   "deposit_description"
    t.string   "deposit_method"
    t.string   "profile_full_name"
    t.string   "profile_credit_card"
    t.string   "profile_last_digits"
    t.string   "deposit_amount"
    t.string   "available_funds"
    t.string   "order_reference_number"
    t.string   "order_created_at"
    t.string   "line_item_descriptions"
    t.string   "line_item_amounts"
    t.string   "order_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reminder_triggers", :force => true do |t|
    t.integer  "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "renewal_attempts", :force => true do |t|
    t.integer  "certificate_order_id"
    t.integer  "order_transaction_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "renewal_notifications", :force => true do |t|
    t.integer  "certificate_order_id"
    t.text     "body"
    t.string   "recipients"
    t.string   "subject"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "reseller_tiers", :force => true do |t|
    t.string   "label"
    t.string   "description"
    t.integer  "amount"
    t.string   "roles"
    t.string   "published_as"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resellers", :force => true do |t|
    t.integer  "ssl_account_id"
    t.integer  "reseller_tier_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "organization"
    t.string   "address1"
    t.string   "address2"
    t.string   "address3"
    t.string   "po_box"
    t.string   "postal_code"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "ext"
    t.string   "fax"
    t.string   "website"
    t.string   "tax_number"
    t.string   "roles"
    t.string   "type_organization"
    t.string   "workflow_state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sent_reminders", :force => true do |t|
    t.integer  "signed_certificate_id"
    t.text     "body"
    t.string   "recipients"
    t.string   "subject"
    t.string   "trigger_value"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "server_softwares", :force => true do |t|
    t.string   "title",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "support_url"
  end

  create_table "signed_certificates", :force => true do |t|
    t.integer  "csr_id"
    t.integer  "parent_id"
    t.string   "common_name"
    t.string   "organization"
    t.text     "organization_unit"
    t.string   "address1"
    t.string   "address2"
    t.string   "locality"
    t.string   "state"
    t.string   "postal_code"
    t.string   "country"
    t.datetime "effective_date"
    t.datetime "expiration_date"
    t.string   "fingerprintSHA"
    t.string   "fingerprint"
    t.text     "signature"
    t.string   "url"
    t.text     "body"
    t.boolean  "parent_cert"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names"
    t.integer  "strength"
    t.integer  "certificate_lookup_id"
  end

  add_index "signed_certificates", ["csr_id"], :name => "index_signed_certificates_on_csr_id"

  create_table "site_checks", :force => true do |t|
    t.text     "url"
    t.integer  "certificate_lookup_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_seals", :force => true do |t|
    t.string   "workflow_state"
    t.string   "seal_type"
    t.string   "ref"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_seals", ["ref"], :name => "index_site_seals_ref"
  add_index "site_seals", ["workflow_state"], :name => "index_site_seals_workflow_state"

  create_table "ssl_accounts", :force => true do |t|
    t.string   "acct_number"
    t.string   "roles",       :default => "--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ssl_docs", :force => true do |t|
    t.integer  "folder_id"
    t.string   "reviewer"
    t.string   "notes"
    t.string   "admin_notes"
    t.string   "document_file_name"
    t.string   "document_file_size"
    t.string   "document_content_type"
    t.datetime "document_updated_at"
    t.string   "random_secret"
    t.boolean  "processing"
    t.string   "status"
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_order_items", :force => true do |t|
    t.integer  "sub_itemable_id"
    t.string   "sub_itemable_type"
    t.integer  "product_variant_item_id"
    t.integer  "quantity"
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surl_blacklists", :force => true do |t|
    t.string   "fingerprint"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surl_visits", :force => true do |t|
    t.integer  "surl_id"
    t.integer  "visitor_token_id"
    t.string   "referer_host"
    t.string   "referer_address"
    t.string   "request_uri"
    t.string   "http_user_agent"
    t.string   "result"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "surl_visits", ["surl_id"], :name => "index_surl_visits_on_surl_id"

  create_table "surls", :force => true do |t|
    t.integer  "user_id"
    t.text     "original"
    t.string   "identifier"
    t.string   "guid"
    t.string   "username"
    t.string   "password_hash"
    t.string   "password_salt"
    t.boolean  "require_ssl"
    t.boolean  "share"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tracked_urls", :force => true do |t|
    t.text     "url"
    t.string   "md5"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tracked_urls", ["md5", "url"], :name => "index_tracked_urls_on_md5_and_url", :length => {"md5"=>100, "url"=>100}
  add_index "tracked_urls", ["md5"], :name => "index_tracked_urls_on_md5"

  create_table "trackings", :force => true do |t|
    t.integer  "tracked_url_id"
    t.integer  "visitor_token_id"
    t.integer  "referer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip"
  end

  create_table "unsubscribes", :force => true do |t|
    t.string   "specs"
    t.text     "domain"
    t.text     "email"
    t.text     "ref"
    t.boolean  "enforce"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.integer  "ssl_account_id"
    t.string   "login",                                  :null => false
    t.string   "email",                                  :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                      :null => false
    t.string   "single_access_token",                    :null => false
    t.string   "perishable_token",                       :null => false
    t.string   "status"
    t.integer  "login_count",         :default => 0,     :null => false
    t.integer  "failed_login_count",  :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.boolean  "active",              :default => false, :null => false
    t.string   "openid_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "organization"
    t.string   "address1"
    t.string   "address2"
    t.string   "address3"
    t.string   "po_box"
    t.string   "postal_code"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.boolean  "is_auth_token"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"

  create_table "v2_migration_progresses", :force => true do |t|
    t.string   "source_table_name"
    t.integer  "source_id"
    t.integer  "migratable_id"
    t.string   "migratable_type"
    t.datetime "migrated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_histories", :force => true do |t|
    t.integer  "validation_id"
    t.string   "reviewer"
    t.string   "notes"
    t.string   "admin_notes"
    t.string   "document_file_name"
    t.string   "document_file_size"
    t.string   "document_content_type"
    t.datetime "document_updated_at"
    t.string   "random_secret"
    t.boolean  "publish_to_site_seal"
    t.boolean  "publish_to_site_seal_approval", :default => false
    t.string   "satisfies_validation_methods"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "validation_histories", ["validation_id"], :name => "index_validation_histories_validation_id"

  create_table "validation_history_validations", :force => true do |t|
    t.integer  "validation_history_id"
    t.integer  "validation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rules", :force => true do |t|
    t.string   "description"
    t.string   "operator"
    t.integer  "parent_id"
    t.string   "applicable_validation_methods"
    t.string   "required_validation_methods"
    t.string   "required_validation_methods_operator", :default => "AND"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rulings", :force => true do |t|
    t.integer  "validation_rule_id"
    t.integer  "validation_rulable_id"
    t.string   "validation_rulable_type"
    t.string   "workflow_state"
    t.string   "status"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "validation_rulings", ["validation_rulable_id", "validation_rulable_type"], :name => "index_validation_rulings_on_rulable_id_and_rulable_type"
  add_index "validation_rulings", ["validation_rule_id"], :name => "index_validation_rulings_on_validation_rule_id"

  create_table "validation_rulings_validation_histories", :force => true do |t|
    t.integer  "validation_history_id"
    t.integer  "validation_ruling_id"
    t.string   "status"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validations", :force => true do |t|
    t.string   "label"
    t.string   "notes"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "organization"
    t.string   "address1"
    t.string   "address2"
    t.string   "postal_code"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "website"
    t.string   "contact_email"
    t.string   "contact_phone"
    t.string   "tax_number"
    t.string   "workflow_state"
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "visitor_tokens", :force => true do |t|
    t.integer  "user_id"
    t.integer  "affiliate_id"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visitor_tokens", ["guid", "affiliate_id"], :name => "index_visitor_tokens_on_guid_and_affiliate_id"
  add_index "visitor_tokens", ["guid"], :name => "index_visitor_tokens_on_guid"

  create_table "whois_lookups", :force => true do |t|
    t.integer  "csr_id"
    t.text     "raw"
    t.string   "status"
    t.datetime "record_created_on"
    t.datetime "expiration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
