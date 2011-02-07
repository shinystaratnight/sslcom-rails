CREATE TABLE `addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `street1` varchar(255) DEFAULT NULL,
  `street2` varchar(255) DEFAULT NULL,
  `locality` varchar(255) DEFAULT NULL,
  `region` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `affiliates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `contact_phone` varchar(255) DEFAULT NULL,
  `tax_number` varchar(255) DEFAULT NULL,
  `payout_method` varchar(255) DEFAULT NULL,
  `payout_threshold` varchar(255) DEFAULT NULL,
  `payout_frequency` varchar(255) DEFAULT NULL,
  `bank_name` varchar(255) DEFAULT NULL,
  `bank_routing_number` varchar(255) DEFAULT NULL,
  `bank_account_number` varchar(255) DEFAULT NULL,
  `swift_code` varchar(255) DEFAULT NULL,
  `checks_payable_to` varchar(255) DEFAULT NULL,
  `epassporte_account` varchar(255) DEFAULT NULL,
  `paypal_account` varchar(255) DEFAULT NULL,
  `type_organization` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `apis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `billing_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `address_1` varchar(255) DEFAULT NULL,
  `address_2` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `company` varchar(255) DEFAULT NULL,
  `credit_card` varchar(255) DEFAULT NULL,
  `card_number` varchar(255) DEFAULT NULL,
  `expiration_month` int(11) DEFAULT NULL,
  `expiration_year` int(11) DEFAULT NULL,
  `security_code` varchar(255) DEFAULT NULL,
  `last_digits` varchar(255) DEFAULT NULL,
  `data` blob,
  `salt` blob,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `certificate_contents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) NOT NULL,
  `signing_request` text,
  `signed_certificate` text,
  `server_software_id` int(11) DEFAULT NULL,
  `domains` text,
  `duration` int(11) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `billing_checkbox` tinyint(1) DEFAULT NULL,
  `validation_checkbox` tinyint(1) DEFAULT NULL,
  `technical_checkbox` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `certificate_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `validation_id` int(11) DEFAULT NULL,
  `site_seal_id` int(11) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `ref` varchar(255) DEFAULT NULL,
  `num_domains` int(11) DEFAULT NULL,
  `server_licenses` int(11) DEFAULT NULL,
  `line_item_qty` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_expired` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_certificate_orders_on_created_at` (`created_at`),
  KEY `index_certificate_orders_on_is_expired` (`is_expired`),
  KEY `index_certificate_orders_on_ref` (`ref`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reseller_tier_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `summary` text,
  `text_only_summary` text,
  `description` text,
  `text_only_description` text,
  `allow_wildcard_ucc` tinyint(1) DEFAULT NULL,
  `published_as` varchar(16) DEFAULT 'draft',
  `serial` varchar(255) DEFAULT NULL,
  `product` varchar(255) DEFAULT NULL,
  `icons` varchar(255) DEFAULT NULL,
  `display_order` varchar(255) DEFAULT NULL,
  `roles` varchar(255) DEFAULT '--- []',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `po_box` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `address3` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `ext` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `roles` varchar(255) DEFAULT '--- []',
  `contactable_id` int(11) DEFAULT NULL,
  `contactable_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `iso1_code` varchar(255) DEFAULT NULL,
  `name_caps` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `iso3_code` varchar(255) DEFAULT NULL,
  `num_code` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `csrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_content_id` int(11) DEFAULT NULL,
  `body` text,
  `duration` int(11) DEFAULT NULL,
  `common_name` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `organization_unit` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `locality` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `sig_alg` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_csrs_on_common_name` (`common_name`),
  KEY `index_csrs_on_organization` (`organization`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` text,
  `last_error` text,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `deposits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `amount` float DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `credit_card` varchar(255) DEFAULT NULL,
  `last_digits` varchar(255) DEFAULT NULL,
  `payment_method` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `discounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discountable_id` int(11) DEFAULT NULL,
  `discountable_type` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `apply_as` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `ref` varchar(255) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `duplicate_v2_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `funded_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT '0',
  `state` varchar(255) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `gateways` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service` varchar(255) DEFAULT NULL,
  `login` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `mode` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `groupings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `nav_tool` varchar(255) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `legacy_v2_user_mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `old_user_id` int(11) DEFAULT NULL,
  `user_mappable_id` int(11) DEFAULT NULL,
  `user_mappable_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `line_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `affiliate_id` int(11) DEFAULT NULL,
  `sellable_id` int(11) DEFAULT NULL,
  `sellable_type` varchar(255) DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `affiliate_payout_rate` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_line_items_on_order_id` (`order_id`),
  KEY `index_line_items_on_sellable_id` (`sellable_id`),
  KEY `index_line_items_on_sellable_type` (`sellable_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(50) DEFAULT '',
  `note` text,
  `notable_id` int(11) DEFAULT NULL,
  `notable_type` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notes_on_notable_id` (`notable_id`),
  KEY `index_notes_on_notable_type` (`notable_type`),
  KEY `index_notes_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `order_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `reference` varchar(255) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `params` text,
  `avs` text,
  `cvv` text,
  `fraud_review` varchar(255) DEFAULT NULL,
  `test` tinyint(1) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `billing_profile_id` int(11) DEFAULT NULL,
  `billable_id` int(11) DEFAULT NULL,
  `billable_type` varchar(255) DEFAULT NULL,
  `address_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `canceled_at` datetime DEFAULT NULL,
  `lock_version` int(11) DEFAULT '0',
  `description` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT 'pending',
  `status` varchar(255) DEFAULT 'active',
  `reference_number` varchar(255) DEFAULT NULL,
  `deducted_from_id` int(11) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `po_number` varchar(255) DEFAULT NULL,
  `quote_number` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_orders_on_billable_id` (`billable_id`),
  KEY `index_orders_on_billable_type` (`billable_type`),
  KEY `index_orders_on_created_at` (`created_at`),
  KEY `index_orders_on_po_number` (`po_number`),
  KEY `index_orders_on_quote_number` (`quote_number`),
  KEY `index_orders_on_reference_number` (`reference_number`),
  KEY `index_orders_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `address_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `confirmation` varchar(255) DEFAULT NULL,
  `cleared_at` datetime DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `lock_version` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_payments_on_cleared_at` (`cleared_at`),
  KEY `index_payments_on_created_at` (`created_at`),
  KEY `index_payments_on_order_id` (`order_id`),
  KEY `index_payments_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `owner_type` varchar(255) NOT NULL,
  `group_id` int(11) DEFAULT NULL,
  `group_type` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_preferences_on_owner_and_name_and_preference` (`group_id`,`group_type`,`name`,`owner_id`,`owner_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `product_variant_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `variantable_id` int(11) DEFAULT NULL,
  `variantable_type` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `description` text,
  `text_only_description` text,
  `display_order` int(11) DEFAULT NULL,
  `serial` varchar(255) DEFAULT NULL,
  `published_as` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `product_variant_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_variant_group_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `description` text,
  `text_only_description` text,
  `amount` int(11) DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  `item_type` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `serial` varchar(255) DEFAULT NULL,
  `published_as` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `receipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `confirmation_recipients` varchar(255) DEFAULT NULL,
  `receipt_recipients` varchar(255) DEFAULT NULL,
  `processed_recipients` varchar(255) DEFAULT NULL,
  `deposit_reference_number` varchar(255) DEFAULT NULL,
  `deposit_created_at` varchar(255) DEFAULT NULL,
  `deposit_description` varchar(255) DEFAULT NULL,
  `deposit_method` varchar(255) DEFAULT NULL,
  `profile_full_name` varchar(255) DEFAULT NULL,
  `profile_credit_card` varchar(255) DEFAULT NULL,
  `profile_last_digits` varchar(255) DEFAULT NULL,
  `deposit_amount` varchar(255) DEFAULT NULL,
  `available_funds` varchar(255) DEFAULT NULL,
  `order_reference_number` varchar(255) DEFAULT NULL,
  `order_created_at` varchar(255) DEFAULT NULL,
  `line_item_descriptions` varchar(255) DEFAULT NULL,
  `line_item_amounts` varchar(255) DEFAULT NULL,
  `order_amount` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `reminder_triggers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `reseller_tiers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `roles` varchar(255) DEFAULT NULL,
  `published_as` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `resellers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `reseller_tier_id` int(11) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `address3` varchar(255) DEFAULT NULL,
  `po_box` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `ext` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `tax_number` varchar(255) DEFAULT NULL,
  `roles` varchar(255) DEFAULT NULL,
  `type_organization` varchar(255) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `sent_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `signed_certificate_id` int(11) DEFAULT NULL,
  `body` text,
  `recipients` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `trigger_value` varchar(255) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `server_softwares` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `signed_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `common_name` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `organization_unit` text,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `locality` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `effective_date` datetime DEFAULT NULL,
  `expiration_date` datetime DEFAULT NULL,
  `fingerprintSHA` varchar(255) DEFAULT NULL,
  `fingerprint` varchar(255) DEFAULT NULL,
  `signature` text,
  `url` varchar(255) DEFAULT NULL,
  `body` text,
  `parent_cert` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `site_seals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_state` varchar(255) DEFAULT NULL,
  `seal_type` varchar(255) DEFAULT NULL,
  `ref` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ssl_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `acct_number` varchar(255) DEFAULT NULL,
  `roles` varchar(255) DEFAULT '--- []',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ssl_docs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `folder_id` int(11) DEFAULT NULL,
  `reviewer` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `admin_notes` varchar(255) DEFAULT NULL,
  `document_file_name` varchar(255) DEFAULT NULL,
  `document_file_size` varchar(255) DEFAULT NULL,
  `document_content_type` varchar(255) DEFAULT NULL,
  `document_updated_at` datetime DEFAULT NULL,
  `random_secret` varchar(255) DEFAULT NULL,
  `processing` tinyint(1) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `sub_order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sub_itemable_id` int(11) DEFAULT NULL,
  `sub_itemable_type` varchar(255) DEFAULT NULL,
  `product_variant_item_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tracked_urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` text,
  `md5` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `trackings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tracked_url_id` int(11) DEFAULT NULL,
  `visitor_token_id` int(11) DEFAULT NULL,
  `referer_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `login` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `crypted_password` varchar(255) DEFAULT NULL,
  `password_salt` varchar(255) DEFAULT NULL,
  `persistence_token` varchar(255) NOT NULL,
  `single_access_token` varchar(255) NOT NULL,
  `perishable_token` varchar(255) NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT '0',
  `failed_login_count` int(11) NOT NULL DEFAULT '0',
  `last_request_at` datetime DEFAULT NULL,
  `current_login_at` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `current_login_ip` varchar(255) DEFAULT NULL,
  `last_login_ip` varchar(255) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `openid_identifier` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `address3` varchar(255) DEFAULT NULL,
  `po_box` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_users_on_email` (`email`),
  KEY `index_users_on_login` (`login`),
  KEY `index_users_on_perishable_token` (`perishable_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `v2_migration_progresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_table_name` varchar(255) DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `migratable_id` int(11) DEFAULT NULL,
  `migratable_type` varchar(255) DEFAULT NULL,
  `migrated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validation_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_id` int(11) DEFAULT NULL,
  `reviewer` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `admin_notes` varchar(255) DEFAULT NULL,
  `document_file_name` varchar(255) DEFAULT NULL,
  `document_file_size` varchar(255) DEFAULT NULL,
  `document_content_type` varchar(255) DEFAULT NULL,
  `document_updated_at` datetime DEFAULT NULL,
  `random_secret` varchar(255) DEFAULT NULL,
  `publish_to_site_seal` tinyint(1) DEFAULT NULL,
  `publish_to_site_seal_approval` tinyint(1) DEFAULT '0',
  `satisfies_validation_methods` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validation_history_validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_history_id` int(11) DEFAULT NULL,
  `validation_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validation_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `operator` varchar(255) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `applicable_validation_methods` varchar(255) DEFAULT NULL,
  `required_validation_methods` varchar(255) DEFAULT NULL,
  `required_validation_methods_operator` varchar(255) DEFAULT 'AND',
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validation_rulings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_rule_id` int(11) DEFAULT NULL,
  `validation_rulable_id` int(11) DEFAULT NULL,
  `validation_rulable_type` varchar(255) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validation_rulings_validation_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_history_id` int(11) DEFAULT NULL,
  `validation_ruling_id` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `contact_phone` varchar(255) DEFAULT NULL,
  `tax_number` varchar(255) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `domain` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `visitor_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `affiliate_id` int(11) DEFAULT NULL,
  `guid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `whois_lookups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `raw` text,
  `status` varchar(255) DEFAULT NULL,
  `record_created_on` datetime DEFAULT NULL,
  `expiration` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO schema_migrations (version) VALUES ('20100121221021');

INSERT INTO schema_migrations (version) VALUES ('20100122044255');

INSERT INTO schema_migrations (version) VALUES ('20100124195538');

INSERT INTO schema_migrations (version) VALUES ('20100124195613');

INSERT INTO schema_migrations (version) VALUES ('20100125211522');

INSERT INTO schema_migrations (version) VALUES ('20100126175403');

INSERT INTO schema_migrations (version) VALUES ('20100126183131');

INSERT INTO schema_migrations (version) VALUES ('20100126191936');

INSERT INTO schema_migrations (version) VALUES ('20100126192548');

INSERT INTO schema_migrations (version) VALUES ('20100126192837');

INSERT INTO schema_migrations (version) VALUES ('20100126194023');

INSERT INTO schema_migrations (version) VALUES ('20100126194244');

INSERT INTO schema_migrations (version) VALUES ('20100126195542');

INSERT INTO schema_migrations (version) VALUES ('20100126200609');

INSERT INTO schema_migrations (version) VALUES ('20100126200704');

INSERT INTO schema_migrations (version) VALUES ('20100126200716');

INSERT INTO schema_migrations (version) VALUES ('20100201220711');

INSERT INTO schema_migrations (version) VALUES ('20100201235957');

INSERT INTO schema_migrations (version) VALUES ('20100213190715');

INSERT INTO schema_migrations (version) VALUES ('20100213191000');

INSERT INTO schema_migrations (version) VALUES ('20100217042956');

INSERT INTO schema_migrations (version) VALUES ('20100218203748');

INSERT INTO schema_migrations (version) VALUES ('20100303002756');

INSERT INTO schema_migrations (version) VALUES ('20100309223207');

INSERT INTO schema_migrations (version) VALUES ('20100315152101');

INSERT INTO schema_migrations (version) VALUES ('20100318032118');

INSERT INTO schema_migrations (version) VALUES ('20100319100957');

INSERT INTO schema_migrations (version) VALUES ('20100323022436');

INSERT INTO schema_migrations (version) VALUES ('20100420222202');

INSERT INTO schema_migrations (version) VALUES ('20100420222227');

INSERT INTO schema_migrations (version) VALUES ('20100528061603');

INSERT INTO schema_migrations (version) VALUES ('20100528062845');

INSERT INTO schema_migrations (version) VALUES ('20100529211634');

INSERT INTO schema_migrations (version) VALUES ('20100530202931');

INSERT INTO schema_migrations (version) VALUES ('20100604202312');

INSERT INTO schema_migrations (version) VALUES ('20100616170837');

INSERT INTO schema_migrations (version) VALUES ('20100719190953');

INSERT INTO schema_migrations (version) VALUES ('20100809215106');

INSERT INTO schema_migrations (version) VALUES ('20100921154727');

INSERT INTO schema_migrations (version) VALUES ('20100921155158');

INSERT INTO schema_migrations (version) VALUES ('20100923222042');

INSERT INTO schema_migrations (version) VALUES ('20101019040011');

INSERT INTO schema_migrations (version) VALUES ('20101019135512');

INSERT INTO schema_migrations (version) VALUES ('20101031183441');

INSERT INTO schema_migrations (version) VALUES ('20101210164349');

INSERT INTO schema_migrations (version) VALUES ('20101213233052');

INSERT INTO schema_migrations (version) VALUES ('20101218195702');

INSERT INTO schema_migrations (version) VALUES ('20101231223811');

INSERT INTO schema_migrations (version) VALUES ('20110127235349');