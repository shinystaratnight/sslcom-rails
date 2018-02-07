class ConvertLatin1ToUtf8 < ActiveRecord::Migration
  def db
    ActiveRecord::Base.connection
  end
  
  def target_tables
    [
      "blocklists",
      "ca_api_requests",
      "caa_checks",
      "cas",
      "certificate_api_requests",
      "certificate_names",
      "certificates_products",
      "csr_overrides",
      "dbs",
      "delayed_job_groups",
      "discountables_sellables",
      "discounts",
      "discounts_certificates",
      "discounts_orders",
      "domain_control_validations",
      "malware_hashes",
      "malwares",
      "other_party_requests",
      "permissions",
      "permissions_roles",
      "physical_tokens",
      "product_orders",
      "product_orders_sub_product_orders",
      "products",
      "products_sub_products",
      "refunds",
      "renewal_attempts",
      "renewal_notifications",
      "sessions",
      "shopping_carts",
      "ssl_account_users",
      "surl_blacklists",
      "surl_visits",
      "surls",
      "system_audits",
      "user_groups",
      "user_groups_users",
      "websites"
    ]
  end
  
  def up 
    target_tables.each do |table|
      next if %w(ar_internal_metadata schema_migrations delayed_jobs).include?(table)
      execute "ALTER TABLE `#{table}` CHARACTER SET = utf8;"
      db.columns(table).each do |column|
        case column.sql_type 
          when /([a-z]*)text/i
            execute "ALTER TABLE `#{table}` CHANGE `#{column.name}` `#{column.name}` #{$1.upcase}TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
          when /((?:var)?char)\(([0-9]+)\)/i
            # InnoDB has a maximum index length of 767 bytes, so for utf8 or utf8mb4
            # columns, you can index a maximum of 255 or 191 characters, respectively.
            # If you currently have utf8 columns with indexes longer than 191 characters,
            # you will need to index a smaller number of characters.
            indexed_column = db.indexes(table).any? { |index| index.columns.include?(column.name) }

            sql_type = (indexed_column && $2.to_i > 191) ? "#{$1}(191)" : column.sql_type.upcase
            default = (column.default.nil?) ? '' : "DEFAULT '#{column.default}'"
            null = (column.null) ? '' : 'NOT NULL'
            execute "ALTER TABLE `#{table}` CHANGE `#{column.name}` `#{column.name}` #{sql_type} CHARACTER SET utf8 COLLATE utf8_unicode_ci #{default} #{null};"
        end
      end
    end
  end
end
