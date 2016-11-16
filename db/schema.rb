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

ActiveRecord::Schema.define(version: 20161111214702) do

  create_table "addresses", force: :cascade do |t|
    t.string "name",        limit: 255
    t.string "street1",     limit: 255
    t.string "street2",     limit: 255
    t.string "locality",    limit: 255
    t.string "region",      limit: 255
    t.string "postal_code", limit: 255
    t.string "country",     limit: 255
    t.string "phone",       limit: 255
  end

  create_table "affiliates", force: :cascade do |t|
    t.integer  "ssl_account_id",      limit: 4
    t.string   "first_name",          limit: 255
    t.string   "last_name",           limit: 255
    t.string   "email",               limit: 255
    t.string   "phone",               limit: 255
    t.string   "organization",        limit: 255
    t.string   "address1",            limit: 255
    t.string   "address2",            limit: 255
    t.string   "postal_code",         limit: 255
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "country",             limit: 255
    t.string   "website",             limit: 255
    t.string   "contact_email",       limit: 255
    t.string   "contact_phone",       limit: 255
    t.string   "tax_number",          limit: 255
    t.string   "payout_method",       limit: 255
    t.string   "payout_threshold",    limit: 255
    t.string   "payout_frequency",    limit: 255
    t.string   "bank_name",           limit: 255
    t.string   "bank_routing_number", limit: 255
    t.string   "bank_account_number", limit: 255
    t.string   "swift_code",          limit: 255
    t.string   "checks_payable_to",   limit: 255
    t.string   "epassporte_account",  limit: 255
    t.string   "paypal_account",      limit: 255
    t.string   "type_organization",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "api_credentials", force: :cascade do |t|
    t.integer  "ssl_account_id", limit: 4
    t.string   "account_key",    limit: 255
    t.string   "secret_key",     limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "apis", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "role_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ssl_account_id", limit: 4
  end

  add_index "assignments", ["user_id", "ssl_account_id", "role_id"], name: "index_assignments_on_user_id_and_ssl_account_id_and_role_id", using: :btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "provider",   limit: 255
    t.string   "uid",        limit: 255
    t.string   "email",      limit: 255
    t.string   "first_name", limit: 255
    t.string   "last_name",  limit: 255
    t.string   "nick_name",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auto_renewals", force: :cascade do |t|
    t.integer  "certificate_order_id", limit: 4
    t.integer  "order_id",             limit: 4
    t.text     "body",                 limit: 65535
    t.string   "recipients",           limit: 255
    t.string   "subject",              limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "billing_profiles", force: :cascade do |t|
    t.integer  "ssl_account_id",             limit: 4
    t.string   "description",                limit: 255
    t.string   "first_name",                 limit: 255
    t.string   "last_name",                  limit: 255
    t.string   "address_1",                  limit: 255
    t.string   "address_2",                  limit: 255
    t.string   "country",                    limit: 255
    t.string   "city",                       limit: 255
    t.string   "state",                      limit: 255
    t.string   "postal_code",                limit: 255
    t.string   "phone",                      limit: 255
    t.string   "company",                    limit: 255
    t.string   "credit_card",                limit: 255
    t.string   "card_number",                limit: 255
    t.integer  "expiration_month",           limit: 4
    t.integer  "expiration_year",            limit: 4
    t.string   "security_code",              limit: 255
    t.string   "last_digits",                limit: 255
    t.binary   "data",                       limit: 65535
    t.binary   "salt",                       limit: 65535
    t.string   "notes",                      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_card_number",      limit: 255
    t.string   "encrypted_card_number_salt", limit: 255
    t.string   "encrypted_card_number_iv",   limit: 255
    t.string   "vat",                        limit: 255
    t.string   "tax",                        limit: 255
    t.string   "status",                     limit: 255
  end

  add_index "billing_profiles", ["ssl_account_id"], name: "index_billing_profile_on_ssl_account_id", using: :btree

  create_table "ca_api_requests", force: :cascade do |t|
    t.integer  "api_requestable_id",   limit: 4
    t.string   "api_requestable_type", limit: 255
    t.string   "request_url",          limit: 255
    t.text     "parameters",           limit: 65535
    t.string   "method",               limit: 255
    t.text     "response",             limit: 65535
    t.string   "type",                 limit: 255
    t.string   "ca",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_request",          limit: 65535
    t.text     "request_method",       limit: 65535
  end

  create_table "certificate_api_requests", force: :cascade do |t|
    t.integer  "server_software_id",                limit: 4
    t.integer  "country_id",                        limit: 4
    t.string   "account_key",                       limit: 255
    t.string   "secret_key",                        limit: 255
    t.boolean  "test"
    t.string   "product",                           limit: 255
    t.integer  "period",                            limit: 4
    t.integer  "server_count",                      limit: 4
    t.string   "other_domains",                     limit: 255
    t.string   "common_names_flag",                 limit: 255
    t.text     "csr",                               limit: 65535
    t.string   "organization_name",                 limit: 255
    t.string   "post_office_box",                   limit: 255
    t.string   "street_address_1",                  limit: 255
    t.string   "street_address_2",                  limit: 255
    t.string   "street_address_3",                  limit: 255
    t.string   "locality_name",                     limit: 255
    t.string   "state_or_province_name",            limit: 255
    t.string   "postal_code",                       limit: 255
    t.string   "duns_number",                       limit: 255
    t.string   "company_number",                    limit: 255
    t.string   "registered_locality_name",          limit: 255
    t.string   "registered_state_or_province_name", limit: 255
    t.string   "registered_country_name",           limit: 255
    t.string   "assumed_name",                      limit: 255
    t.string   "business_category",                 limit: 255
    t.string   "email_address",                     limit: 255
    t.string   "contact_email_address",             limit: 255
    t.string   "dcv_email_address",                 limit: 255
    t.string   "ca_certificate_id",                 limit: 255
    t.date     "incorporation_date"
    t.boolean  "is_customer_validated"
    t.boolean  "hide_certificate_reference"
    t.string   "external_order_number",             limit: 255
    t.string   "external_order_number_constraint",  limit: 255
    t.string   "response",                          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificate_contents", force: :cascade do |t|
    t.integer  "certificate_order_id", limit: 4,     null: false
    t.text     "signing_request",      limit: 65535
    t.text     "signed_certificate",   limit: 65535
    t.integer  "server_software_id",   limit: 4
    t.text     "domains",              limit: 65535
    t.integer  "duration",             limit: 4
    t.string   "workflow_state",       limit: 255
    t.boolean  "billing_checkbox"
    t.boolean  "validation_checkbox"
    t.boolean  "technical_checkbox"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label",                limit: 255
    t.string   "ref",                  limit: 255
    t.boolean  "agreement"
  end

  add_index "certificate_contents", ["certificate_order_id"], name: "index_certificate_contents_on_certificate_order_id", using: :btree
  add_index "certificate_contents", ["workflow_state"], name: "index_certificate_contents_on_workflow_state", using: :btree

  create_table "certificate_lookups", force: :cascade do |t|
    t.text     "certificate", limit: 65535
    t.string   "serial",      limit: 255
    t.string   "common_name", limit: 255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
  end

  create_table "certificate_names", force: :cascade do |t|
    t.integer  "certificate_content_id", limit: 4
    t.string   "email",                  limit: 255
    t.string   "name",                   limit: 255
    t.boolean  "is_common_name"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "certificate_orders", force: :cascade do |t|
    t.integer  "ssl_account_id",        limit: 4
    t.integer  "validation_id",         limit: 4
    t.integer  "site_seal_id",          limit: 4
    t.string   "workflow_state",        limit: 255
    t.string   "ref",                   limit: 255
    t.integer  "num_domains",           limit: 4
    t.integer  "server_licenses",       limit: 4
    t.integer  "line_item_qty",         limit: 4
    t.integer  "amount",                limit: 4
    t.text     "notes",                 limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_expired"
    t.integer  "renewal_id",            limit: 4
    t.boolean  "is_test"
    t.string   "auto_renew",            limit: 255
    t.string   "auto_renew_status",     limit: 255
    t.string   "ca",                    limit: 255
    t.string   "external_order_number", limit: 255
  end

  add_index "certificate_orders", ["created_at"], name: "index_certificate_orders_on_created_at", using: :btree
  add_index "certificate_orders", ["is_expired"], name: "index_certificate_orders_on_is_expired", using: :btree
  add_index "certificate_orders", ["ref"], name: "index_certificate_orders_on_ref", using: :btree
  add_index "certificate_orders", ["site_seal_id"], name: "index_certificate_orders_site_seal_id", using: :btree
  add_index "certificate_orders", ["workflow_state"], name: "index_certificate_orders_on_workflow_state", using: :btree

  create_table "certificates", force: :cascade do |t|
    t.integer  "reseller_tier_id",      limit: 4
    t.string   "title",                 limit: 255
    t.string   "status",                limit: 255
    t.text     "summary",               limit: 65535
    t.text     "text_only_summary",     limit: 65535
    t.text     "description",           limit: 65535
    t.text     "text_only_description", limit: 65535
    t.boolean  "allow_wildcard_ucc"
    t.string   "published_as",          limit: 16,    default: "draft"
    t.string   "serial",                limit: 255
    t.string   "product",               limit: 255
    t.string   "icons",                 limit: 255
    t.string   "display_order",         limit: 255
    t.string   "roles",                 limit: 255,   default: "--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificates_products", force: :cascade do |t|
    t.integer  "certificate_id", limit: 4
    t.integer  "product_id",     limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "client_applications", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "url",          limit: 255
    t.string   "support_url",  limit: 255
    t.string   "callback_url", limit: 255
    t.string   "key",          limit: 40
    t.string   "secret",       limit: 40
    t.integer  "user_id",      limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "client_applications", ["key"], name: "index_client_applications_on_key", unique: true, using: :btree

  create_table "contacts", force: :cascade do |t|
    t.string   "title",            limit: 255
    t.string   "first_name",       limit: 255
    t.string   "last_name",        limit: 255
    t.string   "company_name",     limit: 255
    t.string   "department",       limit: 255
    t.string   "po_box",           limit: 255
    t.string   "address1",         limit: 255
    t.string   "address2",         limit: 255
    t.string   "address3",         limit: 255
    t.string   "city",             limit: 255
    t.string   "state",            limit: 255
    t.string   "country",          limit: 255
    t.string   "postal_code",      limit: 255
    t.string   "email",            limit: 255
    t.string   "phone",            limit: 255
    t.string   "ext",              limit: 255
    t.string   "fax",              limit: 255
    t.string   "notes",            limit: 255
    t.string   "type",             limit: 255
    t.string   "roles",            limit: 255, default: "--- []"
    t.integer  "contactable_id",   limit: 4
    t.string   "contactable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contacts", ["contactable_id", "contactable_type"], name: "index_contacts_on_contactable_id_and_contactable_type", using: :btree

  create_table "countries", force: :cascade do |t|
    t.string  "iso1_code", limit: 255
    t.string  "name_caps", limit: 255
    t.string  "name",      limit: 255
    t.string  "iso3_code", limit: 255
    t.integer "num_code",  limit: 4
  end

  create_table "csr_overrides", force: :cascade do |t|
    t.integer  "csr_id",            limit: 4
    t.string   "common_name",       limit: 255
    t.string   "organization",      limit: 255
    t.string   "organization_unit", limit: 255
    t.string   "address_1",         limit: 255
    t.string   "address_2",         limit: 255
    t.string   "address_3",         limit: 255
    t.string   "po_box",            limit: 255
    t.string   "state",             limit: 255
    t.string   "locality",          limit: 255
    t.string   "postal_code",       limit: 255
    t.string   "country",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "csrs", force: :cascade do |t|
    t.integer  "certificate_content_id",    limit: 4
    t.text     "body",                      limit: 65535
    t.integer  "duration",                  limit: 4
    t.string   "common_name",               limit: 255
    t.string   "organization",              limit: 255
    t.string   "organization_unit",         limit: 255
    t.string   "state",                     limit: 255
    t.string   "locality",                  limit: 255
    t.string   "country",                   limit: 255
    t.string   "email",                     limit: 255
    t.string   "sig_alg",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names", limit: 65535
    t.integer  "strength",                  limit: 4
    t.boolean  "challenge_password"
    t.integer  "certificate_lookup_id",     limit: 4
    t.text     "decoded",                   limit: 65535
  end

  add_index "csrs", ["certificate_content_id", "common_name"], name: "index_csrs_on_common_name_and_certificate_content_id", using: :btree
  add_index "csrs", ["certificate_content_id"], name: "index_csrs_on_certificate_content_id", using: :btree
  add_index "csrs", ["common_name"], name: "index_csrs_on_common_name", using: :btree
  add_index "csrs", ["organization"], name: "index_csrs_on_organization", using: :btree

  create_table "delayed_job_groups", force: :cascade do |t|
    t.text    "on_completion_job",           limit: 65535
    t.text    "on_completion_job_options",   limit: 65535
    t.text    "on_cancellation_job",         limit: 65535
    t.text    "on_cancellation_job_options", limit: 65535
    t.boolean "queueing_complete",                         default: false, null: false
    t.boolean "blocked",                                   default: false, null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",     limit: 4,     default: 0
    t.integer  "attempts",     limit: 4,     default: 0
    t.text     "handler",      limit: 65535
    t.text     "last_error",   limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue",        limit: 255
    t.boolean  "blocked",                    default: false, null: false
    t.integer  "job_group_id", limit: 4
  end

  add_index "delayed_jobs", ["job_group_id"], name: "index_delayed_jobs_on_job_group_id", using: :btree

  create_table "deposits", force: :cascade do |t|
    t.float    "amount",         limit: 24
    t.string   "full_name",      limit: 255
    t.string   "credit_card",    limit: 255
    t.string   "last_digits",    limit: 255
    t.string   "payment_method", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discountables_sellables", force: :cascade do |t|
    t.integer  "discountable_id",   limit: 4
    t.string   "discountable_type", limit: 255
    t.integer  "sellable_id",       limit: 4
    t.string   "sellable_type",     limit: 255
    t.integer  "amount",            limit: 4
    t.string   "apply_as",          limit: 255
    t.string   "status",            limit: 255
    t.text     "notes",             limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "discounts", force: :cascade do |t|
    t.integer  "discountable_id",   limit: 4
    t.string   "discountable_type", limit: 255
    t.string   "value",             limit: 255
    t.string   "apply_as",          limit: 255
    t.string   "label",             limit: 255
    t.string   "ref",               limit: 255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",            limit: 255
    t.integer  "remaining",         limit: 4
  end

  create_table "discounts_certificates", force: :cascade do |t|
    t.integer  "discount_id",    limit: 4
    t.integer  "certificate_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "discounts_orders", force: :cascade do |t|
    t.integer  "discount_id", limit: 4
    t.integer  "order_id",    limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "domain_control_validations", force: :cascade do |t|
    t.integer  "csr_id",                     limit: 4
    t.string   "email_address",              limit: 255
    t.text     "candidate_addresses",        limit: 65535
    t.string   "subject",                    limit: 255
    t.string   "address_to_find_identifier", limit: 255
    t.string   "identifier",                 limit: 255
    t.boolean  "identifier_found"
    t.datetime "responded_at"
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "workflow_state",             limit: 255
    t.string   "dcv_method",                 limit: 255
    t.integer  "certificate_name_id",        limit: 4
    t.string   "failure_action",             limit: 255
  end

  create_table "duplicate_v2_users", force: :cascade do |t|
    t.string   "login",      limit: 255
    t.string   "email",      limit: 255
    t.string   "password",   limit: 255
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "funded_accounts", force: :cascade do |t|
    t.integer  "ssl_account_id", limit: 4
    t.integer  "cents",          limit: 4,   default: 0
    t.string   "state",          limit: 255
    t.string   "currency",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gateways", force: :cascade do |t|
    t.string "service",  limit: 255
    t.string "login",    limit: 255
    t.string "password", limit: 255
    t.string "mode",     limit: 255
  end

  create_table "groupings", force: :cascade do |t|
    t.integer  "ssl_account_id", limit: 4
    t.string   "type",           limit: 255
    t.string   "name",           limit: 255
    t.string   "nav_tool",       limit: 255
    t.integer  "parent_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",         limit: 255
  end

  create_table "invoices", force: :cascade do |t|
    t.integer  "order_id",    limit: 4
    t.text     "description", limit: 65535
    t.string   "company",     limit: 255
    t.string   "first_name",  limit: 255
    t.string   "last_name",   limit: 255
    t.string   "address_1",   limit: 255
    t.string   "address_2",   limit: 255
    t.string   "country",     limit: 255
    t.string   "city",        limit: 255
    t.string   "state",       limit: 255
    t.string   "postal_code", limit: 255
    t.string   "phone",       limit: 255
    t.string   "fax",         limit: 255
    t.string   "vat",         limit: 255
    t.string   "tax",         limit: 255
    t.string   "notes",       limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "legacy_v2_user_mappings", force: :cascade do |t|
    t.integer  "old_user_id",        limit: 4
    t.integer  "user_mappable_id",   limit: 4
    t.string   "user_mappable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "line_items", force: :cascade do |t|
    t.integer "order_id",              limit: 4
    t.integer "affiliate_id",          limit: 4
    t.integer "sellable_id",           limit: 4
    t.string  "sellable_type",         limit: 255
    t.integer "cents",                 limit: 4
    t.string  "currency",              limit: 255
    t.float   "affiliate_payout_rate", limit: 24
    t.string  "aff_url",               limit: 255
    t.integer "qty",                   limit: 4
  end

  add_index "line_items", ["order_id"], name: "index_line_items_on_order_id", using: :btree
  add_index "line_items", ["sellable_id", "sellable_type"], name: "index_line_items_on_sellable_id_and_sellable_type", using: :btree
  add_index "line_items", ["sellable_id"], name: "index_line_items_on_sellable_id", using: :btree
  add_index "line_items", ["sellable_type"], name: "index_line_items_on_sellable_type", using: :btree

  create_table "malware_hashes", force: :cascade do |t|
    t.string "url", limit: 32, null: false
  end

  add_index "malware_hashes", ["url"], name: "index_malware_hashes_on_url", using: :btree

  create_table "malwares", force: :cascade do |t|
    t.integer  "black_major",   limit: 4
    t.integer  "black_minor",   limit: 4
    t.integer  "malware_major", limit: 4
    t.integer  "malware_minor", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes", force: :cascade do |t|
    t.string   "title",        limit: 50,    default: ""
    t.text     "note",         limit: 65535
    t.integer  "notable_id",   limit: 4
    t.string   "notable_type", limit: 255
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["notable_id"], name: "index_notes_on_notable_id", using: :btree
  add_index "notes", ["notable_type"], name: "index_notes_on_notable_type", using: :btree
  add_index "notes", ["user_id"], name: "index_notes_on_user_id", using: :btree

  create_table "oauth_nonces", force: :cascade do |t|
    t.string   "nonce",      limit: 255
    t.integer  "timestamp",  limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], name: "index_oauth_nonces_on_nonce_and_timestamp", unique: true, using: :btree

  create_table "oauth_tokens", force: :cascade do |t|
    t.integer  "user_id",               limit: 4
    t.string   "type",                  limit: 20
    t.integer  "client_application_id", limit: 4
    t.string   "token",                 limit: 40
    t.string   "secret",                limit: 40
    t.string   "callback_url",          limit: 255
    t.string   "verifier",              limit: 20
    t.string   "scope",                 limit: 255
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "valid_to"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "oauth_tokens", ["token"], name: "index_oauth_tokens_on_token", unique: true, using: :btree

  create_table "order_transactions", force: :cascade do |t|
    t.integer  "order_id",     limit: 4
    t.integer  "amount",       limit: 4
    t.boolean  "success"
    t.string   "reference",    limit: 255
    t.string   "message",      limit: 255
    t.string   "action",       limit: 255
    t.text     "params",       limit: 65535
    t.text     "avs",          limit: 65535
    t.text     "cvv",          limit: 65535
    t.string   "fraud_review", limit: 255
    t.boolean  "test"
    t.string   "notes",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "billing_profile_id",     limit: 4
    t.integer  "billable_id",            limit: 4
    t.string   "billable_type",          limit: 255
    t.integer  "address_id",             limit: 4
    t.integer  "cents",                  limit: 4
    t.string   "currency",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paid_at"
    t.datetime "canceled_at"
    t.integer  "lock_version",           limit: 4,   default: 0
    t.string   "description",            limit: 255
    t.string   "state",                  limit: 255, default: "pending"
    t.string   "status",                 limit: 255, default: "active"
    t.string   "reference_number",       limit: 255
    t.integer  "deducted_from_id",       limit: 4
    t.string   "notes",                  limit: 255
    t.string   "po_number",              limit: 255
    t.string   "quote_number",           limit: 255
    t.integer  "visitor_token_id",       limit: 4
    t.string   "ext_affiliate_name",     limit: 255
    t.string   "ext_affiliate_id",       limit: 255
    t.boolean  "ext_affiliate_credited"
  end

  add_index "orders", ["billable_id", "billable_type"], name: "index_orders_on_billable_id_and_billable_type", using: :btree
  add_index "orders", ["billable_id"], name: "index_orders_on_billable_id", using: :btree
  add_index "orders", ["billable_type"], name: "index_orders_on_billable_type", using: :btree
  add_index "orders", ["created_at"], name: "index_orders_on_created_at", using: :btree
  add_index "orders", ["po_number"], name: "index_orders_on_po_number", using: :btree
  add_index "orders", ["quote_number"], name: "index_orders_on_quote_number", using: :btree
  add_index "orders", ["reference_number"], name: "index_orders_on_reference_number", using: :btree
  add_index "orders", ["status"], name: "index_orders_on_status", using: :btree
  add_index "orders", ["updated_at"], name: "index_orders_on_updated_at", using: :btree

  create_table "other_party_requests", force: :cascade do |t|
    t.integer  "other_party_requestable_id",   limit: 4
    t.string   "other_party_requestable_type", limit: 255
    t.integer  "user_id",                      limit: 4
    t.text     "email_addresses",              limit: 65535
    t.string   "identifier",                   limit: 255
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "order_id",     limit: 4
    t.integer  "address_id",   limit: 4
    t.integer  "cents",        limit: 4
    t.string   "currency",     limit: 255
    t.string   "confirmation", limit: 255
    t.datetime "cleared_at"
    t.datetime "voided_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", limit: 4,   default: 0
  end

  add_index "payments", ["cleared_at"], name: "index_payments_on_cleared_at", using: :btree
  add_index "payments", ["created_at"], name: "index_payments_on_created_at", using: :btree
  add_index "payments", ["order_id"], name: "index_payments_on_order_id", using: :btree
  add_index "payments", ["updated_at"], name: "index_payments_on_updated_at", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "action",        limit: 255
    t.string   "subject_class", limit: 255
    t.integer  "subject_id",    limit: 4
    t.text     "description",   limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "permissions_roles", force: :cascade do |t|
    t.integer  "permission_id", limit: 4
    t.integer  "role_id",       limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "preferences", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.integer  "owner_id",   limit: 4,   null: false
    t.string   "owner_type", limit: 255, null: false
    t.integer  "group_id",   limit: 4
    t.string   "group_type", limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["group_id", "group_type", "name", "owner_id", "owner_type"], name: "index_preferences_on_owner_and_name_and_preference", unique: true, using: :btree
  add_index "preferences", ["owner_id", "owner_type"], name: "index_preferences_on_owner_id_and_owner_type", using: :btree

  create_table "product_orders", force: :cascade do |t|
    t.integer  "ssl_account_id",    limit: 4
    t.integer  "product_id",        limit: 4
    t.string   "workflow_state",    limit: 255
    t.string   "ref",               limit: 255
    t.string   "auto_renew",        limit: 255
    t.string   "auto_renew_status", limit: 255
    t.boolean  "is_expired"
    t.string   "value",             limit: 255
    t.integer  "amount",            limit: 4
    t.text     "notes",             limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "product_orders", ["created_at"], name: "index_product_orders_on_created_at", using: :btree
  add_index "product_orders", ["is_expired"], name: "index_product_orders_on_is_expired", using: :btree
  add_index "product_orders", ["ref"], name: "index_product_orders_on_ref", using: :btree

  create_table "product_orders_sub_product_orders", force: :cascade do |t|
    t.integer  "product_order_id",     limit: 4
    t.integer  "sub_product_order_id", limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "product_variant_groups", force: :cascade do |t|
    t.integer  "variantable_id",        limit: 4
    t.string   "variantable_type",      limit: 255
    t.string   "title",                 limit: 255
    t.string   "status",                limit: 255
    t.text     "description",           limit: 65535
    t.text     "text_only_description", limit: 65535
    t.integer  "display_order",         limit: 4
    t.string   "serial",                limit: 255
    t.string   "published_as",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_variant_items", force: :cascade do |t|
    t.integer  "product_variant_group_id", limit: 4
    t.string   "title",                    limit: 255
    t.string   "status",                   limit: 255
    t.text     "description",              limit: 65535
    t.text     "text_only_description",    limit: 65535
    t.integer  "amount",                   limit: 4
    t.integer  "display_order",            limit: 4
    t.string   "item_type",                limit: 255
    t.string   "value",                    limit: 255
    t.string   "serial",                   limit: 255
    t.string   "published_as",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: :cascade do |t|
    t.string   "title",                 limit: 255
    t.string   "status",                limit: 255
    t.string   "type",                  limit: 255
    t.string   "value",                 limit: 255
    t.text     "summary",               limit: 65535
    t.text     "text_only_summary",     limit: 65535
    t.text     "description",           limit: 65535
    t.text     "text_only_description", limit: 65535
    t.string   "published_as",          limit: 16,    default: "draft"
    t.string   "ref",                   limit: 255
    t.string   "serial",                limit: 255
    t.string   "icons",                 limit: 255
    t.integer  "amount",                limit: 4
    t.integer  "duration",              limit: 4
    t.text     "notes",                 limit: 65535
    t.string   "auto_renew",            limit: 255
    t.string   "display_order",         limit: 255
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  create_table "products_sub_products", force: :cascade do |t|
    t.integer  "product_id",     limit: 4
    t.integer  "sub_product_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "receipts", force: :cascade do |t|
    t.integer  "order_id",                 limit: 4
    t.string   "confirmation_recipients",  limit: 255
    t.string   "receipt_recipients",       limit: 255
    t.string   "processed_recipients",     limit: 255
    t.string   "deposit_reference_number", limit: 255
    t.string   "deposit_created_at",       limit: 255
    t.string   "deposit_description",      limit: 255
    t.string   "deposit_method",           limit: 255
    t.string   "profile_full_name",        limit: 255
    t.string   "profile_credit_card",      limit: 255
    t.string   "profile_last_digits",      limit: 255
    t.string   "deposit_amount",           limit: 255
    t.string   "available_funds",          limit: 255
    t.string   "order_reference_number",   limit: 255
    t.string   "order_created_at",         limit: 255
    t.string   "line_item_descriptions",   limit: 255
    t.string   "line_item_amounts",        limit: 255
    t.string   "order_amount",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reminder_triggers", force: :cascade do |t|
    t.integer  "name",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "renewal_attempts", force: :cascade do |t|
    t.integer  "certificate_order_id", limit: 4
    t.integer  "order_transaction_id", limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "renewal_notifications", force: :cascade do |t|
    t.integer  "certificate_order_id", limit: 4
    t.text     "body",                 limit: 65535
    t.string   "recipients",           limit: 255
    t.string   "subject",              limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "reseller_tiers", force: :cascade do |t|
    t.string   "label",        limit: 255
    t.string   "description",  limit: 255
    t.integer  "amount",       limit: 4
    t.string   "roles",        limit: 255
    t.string   "published_as", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resellers", force: :cascade do |t|
    t.integer  "ssl_account_id",    limit: 4
    t.integer  "reseller_tier_id",  limit: 4
    t.string   "first_name",        limit: 255
    t.string   "last_name",         limit: 255
    t.string   "email",             limit: 255
    t.string   "phone",             limit: 255
    t.string   "organization",      limit: 255
    t.string   "address1",          limit: 255
    t.string   "address2",          limit: 255
    t.string   "address3",          limit: 255
    t.string   "po_box",            limit: 255
    t.string   "postal_code",       limit: 255
    t.string   "city",              limit: 255
    t.string   "state",             limit: 255
    t.string   "country",           limit: 255
    t.string   "ext",               limit: 255
    t.string   "fax",               limit: 255
    t.string   "website",           limit: 255
    t.string   "tax_number",        limit: 255
    t.string   "roles",             limit: 255
    t.string   "type_organization", limit: 255
    t.string   "workflow_state",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ssl_account_id", limit: 4
    t.text     "description",    limit: 65535
    t.string   "status",         limit: 255
  end

  create_table "sent_reminders", force: :cascade do |t|
    t.integer  "signed_certificate_id", limit: 4
    t.text     "body",                  limit: 65535
    t.string   "recipients",            limit: 255
    t.string   "subject",               limit: 255
    t.string   "trigger_value",         limit: 255
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "server_softwares", force: :cascade do |t|
    t.string   "title",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "support_url", limit: 255
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shopping_carts", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.string   "guid",             limit: 255
    t.text     "content",          limit: 65535
    t.string   "token",            limit: 255
    t.string   "crypted_password", limit: 255
    t.string   "password_salt",    limit: 255
    t.string   "access",           limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "signed_certificates", force: :cascade do |t|
    t.integer  "csr_id",                    limit: 4
    t.integer  "parent_id",                 limit: 4
    t.string   "common_name",               limit: 255
    t.string   "organization",              limit: 255
    t.text     "organization_unit",         limit: 65535
    t.string   "address1",                  limit: 255
    t.string   "address2",                  limit: 255
    t.string   "locality",                  limit: 255
    t.string   "state",                     limit: 255
    t.string   "postal_code",               limit: 255
    t.string   "country",                   limit: 255
    t.datetime "effective_date"
    t.datetime "expiration_date"
    t.string   "fingerprintSHA",            limit: 255
    t.string   "fingerprint",               limit: 255
    t.text     "signature",                 limit: 65535
    t.string   "url",                       limit: 255
    t.text     "body",                      limit: 65535
    t.boolean  "parent_cert"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject_alternative_names", limit: 65535
    t.integer  "strength",                  limit: 4
    t.integer  "certificate_lookup_id",     limit: 4
    t.text     "decoded",                   limit: 65535
  end

  add_index "signed_certificates", ["csr_id"], name: "index_signed_certificates_on_csr_id", using: :btree

  create_table "site_checks", force: :cascade do |t|
    t.text     "url",                   limit: 65535
    t.integer  "certificate_lookup_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_seals", force: :cascade do |t|
    t.string   "workflow_state", limit: 255
    t.string   "seal_type",      limit: 255
    t.string   "ref",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_seals", ["ref"], name: "index_site_seals_ref", using: :btree
  add_index "site_seals", ["workflow_state"], name: "index_site_seals_workflow_state", using: :btree

  create_table "ssl_account_users", force: :cascade do |t|
    t.integer  "user_id",        limit: 4, null: false
    t.integer  "ssl_account_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "approved",                   default: false
    t.string   "approval_token", limit: 255
    t.datetime "token_expires"
  end

  add_index "ssl_account_users", ["ssl_account_id", "user_id"], name: "index_ssl_account_users_on_ssl_account_id_and_user_id", using: :btree
  add_index "ssl_account_users", ["ssl_account_id"], name: "index_ssl_account_users_on_ssl_account_id", using: :btree
  add_index "ssl_account_users", ["user_id"], name: "index_ssl_account_users_on_user_id", using: :btree

  create_table "ssl_accounts", force: :cascade do |t|
    t.string   "acct_number", limit: 255
    t.string   "roles",       limit: 255, default: "--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",      limit: 255
  end

  add_index "ssl_accounts", ["acct_number"], name: "index_ssl_account_on_acct_number", using: :btree

  create_table "ssl_docs", force: :cascade do |t|
    t.integer  "folder_id",             limit: 4
    t.string   "reviewer",              limit: 255
    t.string   "notes",                 limit: 255
    t.string   "admin_notes",           limit: 255
    t.string   "document_file_name",    limit: 255
    t.string   "document_file_size",    limit: 255
    t.string   "document_content_type", limit: 255
    t.datetime "document_updated_at"
    t.string   "random_secret",         limit: 255
    t.boolean  "processing"
    t.string   "status",                limit: 255
    t.string   "display_name",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_order_items", force: :cascade do |t|
    t.integer  "sub_itemable_id",         limit: 4
    t.string   "sub_itemable_type",       limit: 255
    t.integer  "product_variant_item_id", limit: 4
    t.integer  "quantity",                limit: 4
    t.integer  "amount",                  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_id",              limit: 4
  end

  create_table "surl_blacklists", force: :cascade do |t|
    t.string   "fingerprint", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surl_visits", force: :cascade do |t|
    t.integer  "surl_id",          limit: 4
    t.integer  "visitor_token_id", limit: 4
    t.string   "referer_host",     limit: 255
    t.string   "referer_address",  limit: 255
    t.string   "request_uri",      limit: 255
    t.string   "http_user_agent",  limit: 255
    t.string   "result",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "surl_visits", ["surl_id"], name: "index_surl_visits_on_surl_id", using: :btree

  create_table "surls", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.text     "original",      limit: 65535
    t.string   "identifier",    limit: 255
    t.string   "guid",          limit: 255
    t.string   "username",      limit: 255
    t.string   "password_hash", limit: 255
    t.string   "password_salt", limit: 255
    t.boolean  "require_ssl"
    t.boolean  "share"
    t.string   "status",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "system_audits", force: :cascade do |t|
    t.integer  "owner_id",    limit: 4
    t.string   "owner_type",  limit: 255
    t.integer  "target_id",   limit: 4
    t.string   "target_type", limit: 255
    t.text     "notes",       limit: 65535
    t.string   "action",      limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "tracked_urls", force: :cascade do |t|
    t.text     "url",        limit: 65535
    t.string   "md5",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tracked_urls", ["md5", "url"], name: "index_tracked_urls_on_md5_and_url", length: {"md5"=>100, "url"=>100}, using: :btree
  add_index "tracked_urls", ["md5"], name: "index_tracked_urls_on_md5", using: :btree

  create_table "trackings", force: :cascade do |t|
    t.integer  "tracked_url_id",   limit: 4
    t.integer  "visitor_token_id", limit: 4
    t.integer  "referer_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip",        limit: 255
  end

  create_table "unsubscribes", force: :cascade do |t|
    t.string   "specs",      limit: 255
    t.text     "domain",     limit: 65535
    t.text     "email",      limit: 65535
    t.text     "ref",        limit: 65535
    t.boolean  "enforce"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_groups", force: :cascade do |t|
    t.integer "ssl_account_id", limit: 4
    t.string  "roles",          limit: 255,   default: "--- []"
    t.string  "name",           limit: 255
    t.text    "description",    limit: 65535
    t.text    "notes",          limit: 65535
  end

  create_table "user_groups_users", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "user_group_id", limit: 4
    t.string   "status",        limit: 255
    t.string   "notes",         limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer  "ssl_account_id",      limit: 4
    t.string   "login",               limit: 255,                 null: false
    t.string   "email",               limit: 255,                 null: false
    t.string   "crypted_password",    limit: 255
    t.string   "password_salt",       limit: 255
    t.string   "persistence_token",   limit: 255,                 null: false
    t.string   "single_access_token", limit: 255,                 null: false
    t.string   "perishable_token",    limit: 255,                 null: false
    t.string   "status",              limit: 255
    t.string   "first_name",          limit: 255
    t.string   "last_name",           limit: 255
    t.string   "phone",               limit: 255
    t.string   "organization",        limit: 255
    t.string   "address1",            limit: 255
    t.string   "address2",            limit: 255
    t.string   "address3",            limit: 255
    t.string   "po_box",              limit: 255
    t.string   "postal_code",         limit: 255
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "country",             limit: 255
    t.string   "ext",                 limit: 255
    t.string   "fax",                 limit: 255
    t.string   "website",             limit: 255
    t.string   "tax_number",          limit: 255
    t.integer  "login_count",         limit: 4,   default: 0,     null: false
    t.integer  "failed_login_count",  limit: 4,   default: 0,     null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip",    limit: 255
    t.string   "last_login_ip",       limit: 255
    t.boolean  "active",                          default: false, null: false
    t.string   "openid_identifier",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_auth_token"
    t.integer  "default_ssl_account", limit: 4
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["login"], name: "index_users_on_login", using: :btree
  add_index "users", ["perishable_token"], name: "index_users_on_perishable_token", using: :btree
  add_index "users", ["ssl_account_id", "login", "email"], name: "index_users_on_ssl_account_id_and_login_and_email", using: :btree

  create_table "v2_migration_progresses", force: :cascade do |t|
    t.string   "source_table_name", limit: 255
    t.integer  "source_id",         limit: 4
    t.integer  "migratable_id",     limit: 4
    t.string   "migratable_type",   limit: 255
    t.datetime "migrated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_histories", force: :cascade do |t|
    t.integer  "validation_id",                 limit: 4
    t.string   "reviewer",                      limit: 255
    t.string   "notes",                         limit: 255
    t.string   "admin_notes",                   limit: 255
    t.string   "document_file_name",            limit: 255
    t.string   "document_file_size",            limit: 255
    t.string   "document_content_type",         limit: 255
    t.datetime "document_updated_at"
    t.string   "random_secret",                 limit: 255
    t.boolean  "publish_to_site_seal"
    t.boolean  "publish_to_site_seal_approval",             default: false
    t.string   "satisfies_validation_methods",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "validation_histories", ["validation_id"], name: "index_validation_histories_validation_id", using: :btree

  create_table "validation_history_validations", force: :cascade do |t|
    t.integer  "validation_history_id", limit: 4
    t.integer  "validation_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rules", force: :cascade do |t|
    t.string   "description",                          limit: 255
    t.string   "operator",                             limit: 255
    t.integer  "parent_id",                            limit: 4
    t.string   "applicable_validation_methods",        limit: 255
    t.string   "required_validation_methods",          limit: 255
    t.string   "required_validation_methods_operator", limit: 255, default: "AND"
    t.string   "notes",                                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validation_rulings", force: :cascade do |t|
    t.integer  "validation_rule_id",      limit: 4
    t.integer  "validation_rulable_id",   limit: 4
    t.string   "validation_rulable_type", limit: 255
    t.string   "workflow_state",          limit: 255
    t.string   "status",                  limit: 255
    t.string   "notes",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "validation_rulings", ["validation_rulable_id", "validation_rulable_type"], name: "index_validation_rulings_on_rulable_id_and_rulable_type", using: :btree
  add_index "validation_rulings", ["validation_rule_id"], name: "index_validation_rulings_on_validation_rule_id", using: :btree

  create_table "validation_rulings_validation_histories", force: :cascade do |t|
    t.integer  "validation_history_id", limit: 4
    t.integer  "validation_ruling_id",  limit: 4
    t.string   "status",                limit: 255
    t.string   "notes",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "validations", force: :cascade do |t|
    t.string   "label",          limit: 255
    t.string   "notes",          limit: 255
    t.string   "first_name",     limit: 255
    t.string   "last_name",      limit: 255
    t.string   "email",          limit: 255
    t.string   "phone",          limit: 255
    t.string   "organization",   limit: 255
    t.string   "address1",       limit: 255
    t.string   "address2",       limit: 255
    t.string   "postal_code",    limit: 255
    t.string   "city",           limit: 255
    t.string   "state",          limit: 255
    t.string   "country",        limit: 255
    t.string   "website",        limit: 255
    t.string   "contact_email",  limit: 255
    t.string   "contact_phone",  limit: 255
    t.string   "tax_number",     limit: 255
    t.string   "workflow_state", limit: 255
    t.string   "domain",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "visitor_tokens", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "affiliate_id", limit: 4
    t.string   "guid",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visitor_tokens", ["guid", "affiliate_id"], name: "index_visitor_tokens_on_guid_and_affiliate_id", using: :btree
  add_index "visitor_tokens", ["guid"], name: "index_visitor_tokens_on_guid", using: :btree

  create_table "whois_lookups", force: :cascade do |t|
    t.integer  "csr_id",            limit: 4
    t.text     "raw",               limit: 65535
    t.string   "status",            limit: 255
    t.datetime "record_created_on"
    t.datetime "expiration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
