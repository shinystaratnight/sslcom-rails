class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :affiliates, :ssl_account_id
    add_index :assignments, :role_id
    add_index :assignments, :ssl_account_id
    add_index :assignments, :user_id
    add_index :authentications, :user_id
    add_index :blocklists, [:id, :type]
    add_index :ca_api_requests, [:id, :type]
    add_index :caa_checks, [:checkable_id, :checkable_type]
    add_index :cas, [:id, :type]
    add_index :cas_certificates, :ssl_account_id
    add_index :cdns, :ssl_account_id
    add_index :certificate_contents, :server_software_id
    # add_index :certificate_contents, [:certificate_order_id, :csr_id]
    add_index :certificate_order_domains, :certificate_order_id
    add_index :certificate_order_domains, :domain_id
    # add_index :certificate_order_domains, [:certificate_order_id, :domain_id]
    add_index :certificate_order_managed_csrs, :certificate_order_id
    add_index :certificate_order_managed_csrs, :managed_csr_id
    add_index :certificate_order_tokens, :certificate_order_id
    add_index :certificate_order_tokens, :ssl_account_id
    add_index :certificate_order_tokens, :user_id
    add_index :certificate_orders, :assignee_id
    add_index :certificate_orders, :folder_id
    add_index :certificate_orders, :renewal_id
    add_index :certificates, :reseller_tier_id
    add_index :certificates_products, :certificate_id
    add_index :certificates_products, :product_id
    add_index :certificates_products, [:certificate_id, :product_id]
    add_index :client_applications, :user_id
    add_index :contacts, :parent_id
    # add_index :contacts, :ssl_account_id
    add_index :contacts, [:id, :type]
    # add_index :csr_overrides, :csr_id
    add_index :csr_unique_values, :csr_id
    add_index :csrs, :certificate_lookup_id
    # add_index :csrs, [:certificate_content_id, :signed_certificate_id]
    # add_index :csrs, [:certificate_order_id, :signed_certificate_id]
    add_index :discounts, [:benefactor_id, :benefactor_type]
    add_index :discounts_orders, :discount_id
    add_index :discounts_orders, :order_id
    # add_index :discounts_orders, [:discount_id, :enrollment_order_id]
    add_index :discounts_orders, [:discount_id, :order_id]
    # add_index :discounts_orders, [:discount_id, :reprocess_certificate_order_id]
    # add_index :discounts_orders, [:discount_id, :smime_client_enrollment_order_id]
    add_index :domain_control_validations, :certificate_name_id
    add_index :domain_control_validations, :csr_id
    add_index :domain_control_validations, :csr_unique_value_id
    add_index :domain_control_validations, :validation_compliance_id
    add_index :duo_accounts, :ssl_account_id
    add_index :duplicate_v2_users, :user_id
    add_index :invoices, :order_id
    add_index :invoices, [:billable_id, :billable_type]
    add_index :invoices, [:id, :type]
    # add_index :legacy_v2_user_mappings, [:user_mappable_id, :user_mappable_type]
    add_index :line_items, :affiliate_id
    add_index :notes, [:notable_id, :notable_type]
    # add_index :notification_groups_contacts, [:contactable_id, :contactable_type]
    add_index :oauth_tokens, :client_application_id
    add_index :oauth_tokens, :user_id
    add_index :oauth_tokens, [:id, :type]
    add_index :order_transactions, :order_id
    add_index :orders, :address_id
    add_index :orders, :billing_profile_id
    add_index :orders, :deducted_from_id
    add_index :orders, :invoice_id
    add_index :orders, :reseller_tier_id
    add_index :orders, :visitor_token_id
    add_index :orders, [:id, :type]
    add_index :other_party_requests, :user_id
    # add_index :other_party_requests, [:other_party_requestable_id, :other_party_requestable_type]
    add_index :payments, :address_id
    add_index :permissions_roles, :permission_id
    add_index :permissions_roles, :role_id
    add_index :permissions_roles, [:permission_id, :role_id]
    add_index :physical_tokens, :certificate_order_id
    add_index :physical_tokens, :signed_certificate_id
    add_index :preferences, [:group_id, :group_type]
    add_index :product_orders, :product_id
    add_index :product_orders, :ssl_account_id
    add_index :product_orders_sub_product_orders, :product_order_id
    add_index :product_orders_sub_product_orders, :sub_product_order_id
    # add_index :product_orders_sub_product_orders, [:product_order_id, :sub_product_order_id]
    # add_index :product_orders_sub_product_orders, [:sub_product_order_id, :sub_product_order_id]
    # add_index :product_variant_groups, [:variantable_id, :variantable_type]
    add_index :product_variant_items, :product_variant_group_id
    add_index :products_sub_products, :product_id
    add_index :products_sub_products, :sub_product_id
    add_index :products_sub_products, [:product_id, :sub_product_id]
    # add_index :products_sub_products, [:sub_product_id, :sub_product_id]
    add_index :receipts, :order_id
    add_index :registered_agents, :approver_id
    add_index :registered_agents, :requester_id
    add_index :registered_agents, :ssl_account_id
    add_index :renewal_attempts, :certificate_order_id
    add_index :renewal_attempts, :order_transaction_id
    add_index :renewal_notifications, :certificate_order_id
    add_index :resellers, :reseller_tier_id
    add_index :resellers, :ssl_account_id
    add_index :revocations, :replacement_signed_certificate_id
    add_index :revocations, :revoked_signed_certificate_id
    add_index :roles, :ssl_account_id
    add_index :shopping_carts, :user_id
    add_index :signed_certificates, :certificate_content_id
    add_index :signed_certificates, :certificate_lookup_id
    add_index :signed_certificates, :parent_id
    add_index :signed_certificates, :registered_agent_id
    add_index :signed_certificates, [:id, :type]
    add_index :site_checks, :certificate_lookup_id
    # add_index :ssl_account_users, [:managed_user_id, :ssl_account_id]
    # add_index :ssl_account_users, [:ssl_account_id, :ssl_account_id]
    # add_index :ssl_account_users, [:ssl_account_id, :unscoped_user_id]
    add_index :sub_order_items, :product_id
    add_index :sub_order_items, :product_variant_item_id
    add_index :surl_visits, :visitor_token_id
    add_index :surls, :user_id
    add_index :taggings, [:taggable_id, :taggable_type]
    add_index :trackings, :referer_id
    add_index :trackings, :tracked_url_id
    add_index :trackings, :visitor_token_id
    add_index :u2fs, :user_id
    add_index :url_callbacks, [:callbackable_id, :callbackable_type]
    add_index :user_groups, :ssl_account_id
    add_index :user_groups_users, :user_group_id
    add_index :user_groups_users, :user_id
    # add_index :user_groups_users, [:managed_user_id, :user_group_id]
    # add_index :user_groups_users, [:unscoped_user_id, :user_group_id]
    add_index :user_groups_users, [:user_group_id, :user_id]
    # add_index :v2_migration_progresses, [:migratable_id, :migratable_type]
    add_index :validation_history_validations, :validation_history_id
    add_index :validation_history_validations, :validation_id
    add_index :validation_rules, :parent_id
    # add_index :validation_rulings_validation_histories, :validation_history_id
    # add_index :validation_rulings_validation_histories, :validation_ruling_id
    add_index :visitor_tokens, :affiliate_id
    add_index :visitor_tokens, :user_id
    add_index :websites, :db_id
    add_index :websites, [:id, :type]
    add_index :whois_lookups, :csr_id
  end
end
