Certificate.connection.truncate(Certificate.table_name)
Certificate.create!([
  {reseller_tier_id: nil, title: "Enterprise EV SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Premium EV", "points"=>"<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guaranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div> \n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n", "validation_level"=>"Class 3 DoD", "summary"=>"highest trust assurance\n", "abbr"=>"EV SSL", :certificate_type=>"Enterprise EV"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "ev256", product: "ev", icons: {"main"=>"ev_bar_lg.jpg"}, display_order: {"all"=>1, "index"=>1}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "High Assurance SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"High Assurance", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"standard ssl\n", "abbr"=>"High Assurance SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "ov256", product: "high_assurance", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Free SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Free", "points"=>"<div class='check'>great for testing or development</div>\n<div class='check'>is free with no cost to you</div>\n<div class='check'>activates SSL Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<div class='check'>quick issuance</div>\n", "validation_level"=>"Class 1 DoD", "summary"=>"90-day Basic SSL trial\n", "abbr"=>"Free SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "dv256", product: "free", icons: {"main"=>"silver_lock_lg.gif"}, display_order: {"all"=>5, "index"=>3}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Multi-domain UCC SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"High Assurance UCC", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"for Exchange and Communications Server\n", "abbr"=>"UCC SSL"}, text_only_description: nil, allow_wildcard_ucc: false, published_as: "live", serial: "ucc256", product: "ucc", icons: {"main"=>"silver_locks_lg.gif"}, display_order: {"all"=>6, "index"=>6}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Multi-subdomain Wildcard SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Wildcard", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>unlimited subdomains</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"high validation and trust value", "abbr"=>"Wildcard SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "wc256", product: "wildcard", icons: {"main"=>"gold_locks_lg.gif"}, display_order: {"all"=>4, "index"=>4}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Enterprise EV Multi-domain UCC SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"EV UCC", "points"=>"<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n", "validation_level"=>"Class 3 DoD", "summary"=>"for Exchange and Communications Server\n", "abbr"=>"EV UCC SSL", :certificate_type=>"Enterprise EV UCC"}, text_only_description: nil, allow_wildcard_ucc: false, published_as: "live", serial: "evucc256", product: "evucc", icons: {"main"=>"ev_bar_lg.jpg"}, display_order: {"all"=>2, "index"=>5}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Migrated SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"n/a", "points"=>"", "validation_level"=>"n/a", "summary"=>"migrated ssl certificate\n", "abbr"=>"MIGRATED SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "draft", serial: "mssl", product: "mssl", icons: {"main"=>"ev_bar_lg.jpg"}, display_order: {"all"=>1, "index"=>1}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Enterprise EV Multi-domain UCC SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"EV UCC", "points"=>"<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n", "validation_level"=>"Class 3 DoD", "summary"=>"for Exchange and Communications Server\n", "abbr"=>"EV UCC SSL", :certificate_type=>"Enterprise EV UCC"}, text_only_description: nil, allow_wildcard_ucc: false, published_as: "live", serial: "evucc256sslcom", product: "evucc", icons: {"main"=>"ev_bar_lg.jpg"}, display_order: {"all"=>2, "index"=>5}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Multi-domain UCC SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"High Assurance UCC", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>secure up to 2000 additional domains</div>\n<div class='check'>works on MS Exchange or OWA</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"for Exchange and Communications Server\n", "abbr"=>"UCC SSL"}, text_only_description: nil, allow_wildcard_ucc: false, published_as: "live", serial: "ucc256sslcom", product: "ucc", icons: {"main"=>"silver_locks_lg.gif"}, display_order: {"all"=>6, "index"=>6}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Enterprise EV SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Premium EV", "points"=>"<div class='check'>highest rated trust available</div>\n<div class='check'>enables green navigation bar</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$250,000 USD insurance guaranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div> \n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>dedicated support representative</div>\n<div class='check'>unlimited reissuances</div>\n<div class='check'>daily site scan monitoring</div>\n", "validation_level"=>"Class 3 DoD", "summary"=>"highest trust assurance\n", "abbr"=>"EV SSL", :certificate_type=>"Enterprise EV"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "ev256sslcom", product: "ev", icons: {"main"=>"ev_bar_lg.jpg"}, display_order: {"all"=>1, "index"=>1}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "High Assurance SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"High Assurance", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"standard ssl\n", "abbr"=>"High Assurance SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "ov256sslcom", product: "high_assurance", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Free SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Free", "points"=>"<div class='check'>great for testing or development</div>\n<div class='check'>is free with no cost to you</div>\n<div class='check'>activates SSL Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<div class='check'>quick issuance</div>\n", "validation_level"=>"Class 1 DoD", "summary"=>"90-day Basic SSL trial\n", "abbr"=>"Free SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "dv256sslcom", product: "free", icons: {"main"=>"silver_lock_lg.gif"}, display_order: {"all"=>5, "index"=>3}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Multi-subdomain Wildcard SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Wildcard", "points"=>"<div class='check'>high validation and trust value</div>\n<div class='check'>results in higher sales conversion</div>\n<div class='check'>$125,000 USD insurance guarranty</div>\n<div class='check'>unlimited subdomains</div>\n<div class='check'>activates SSL Secure Site Seal</div>\n<div class='check'>2048 bit public key encryption</div>\n<em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n<div class='check'>quick issuance</div>\n<div class='check'>30 day unconditional refund</div>\n<div class='check'>24 hour support</div>\n<div class='check'>unlimited reissuances</div>\n", "validation_level"=>"Class 2 DoD", "summary"=>"high validation and trust value", "abbr"=>"Wildcard SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "wc256sslcom", product: "wildcard", icons: {"main"=>"gold_locks_lg.gif"}, display_order: {"all"=>4, "index"=>4}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Premium Multi-subdomain SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Premium SSL", "points"=>"<div class='check'>quick domain validation</div>\n                               <div class='check'>results in higher sales conversion</div>\n                               <div class='check'>$10,000 USD insurance guaranty</div>\n                               <div class='check'>works on MS Exchange or OWA</div>\n                               <div class='check'>activates SSL Secure Site Seal</div>\n                               <div class='check'>2048 bit public key encryption</div>\n                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n                               <div class='check'>quick issuance</div>\n                               <div class='check'>30 day unconditional refund</div>\n                               <div class='check'>24 hour support</div>\n                               <div class='check'>unlimited reissuances</div>", "validation_level"=>"domain", "summary"=>"ssl for up to 3 subdomains\n", "abbr"=>"Premium SSL"}, text_only_description: nil, allow_wildcard_ucc: false, published_as: "live", serial: "premium256sslcom", product: "premiumssl", icons: {"main"=>"silver_locks_lg.gif"}, display_order: {"all"=>6, "index"=>6}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Basic SSL", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Basic SSL", "points"=>"<div class='check'>quick domain validation</div>\n                               <div class='check'>results in higher sales conversion</div>\n                               <div class='check'>$10,000 USD insurance guaranty</div>\n                               <div class='check'>activates SSL Secure Site Seal</div>\n                               <div class='check'>2048 bit public key encryption</div>\n                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n                               <div class='check'>quick issuance</div>\n                               <div class='check'>30 day unconditional refund</div>\n                               <div class='check'>24 hour support</div>\n                               <div class='check'>unlimited reissuances</div>", "validation_level"=>"domain", "summary"=>"for securing small sites", "abbr"=>"Basic SSL"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "basic256sslcom", product: "basicssl", icons: {"main"=>"silver_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Code Signing", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Code Signing", "points"=>"<div class='check'>organization validation</div>\n                               <div class='check'>results in higher sales conversion</div>\n                               <div class='check'>$150,000 USD insurance guaranty</div>\n                               <div class='check'>activates SSL Secure Site Seal</div>\n                               <div class='check'>2048 bit public key encryption</div>\n                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n                               <div class='check'>quick issuance</div>\n                               <div class='check'>30 day unconditional refund</div>\n                               <div class='check'>24 hour support</div>\n                               <div class='check'>unlimited reissuances</div>", "validation_level"=>"organization", "summary"=>"for securing installable apps and plugins", "abbr"=>"Code Signing"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "codesigning256sslcom", product: "code-signing", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "EV Code Signing", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"EV Code Signing", "points"=>"<div class='check'>extended validation</div>\n                               <div class='check'>results in higher sales conversion</div>\n                               <div class='check'>$2 million USD insurance guaranty</div>\n                               <div class='check'>works with Microsfot Smartscreen</div>\n                               <div class='check'>2048 bit public key encryption</div>\n                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>\n                               <div class='check'>quick issuance</div>\n                               <div class='check'>30 day unconditional refund</div>\n                               <div class='check'>stored on fips 140-2 USB token</div>\n                               <div class='check'>24 hour support</div>", "validation_level"=>"extended", "summary"=>"for securing installable apps and plugins", "abbr"=>"EV Code Signing"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "evcodesigning256sslcom", product: "ev-code-signing", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: []},
  {reseller_tier_id: nil, title: "Personal Basic", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Personal Basic", "points"=>"", "validation_level"=>"class 1", "summary"=>"for authenticating and encrypting email and well as client services", "abbr"=>"Personal Basic"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "personalbasic256sslcom", product: "personal-basic", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: nil},
  {reseller_tier_id: nil, title: "Personal Business", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Personal Business", "points"=>"", "validation_level"=>"class 2", "summary"=>"for authenticating and encrypting email and well as client services", "abbr"=>"Personal Business"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "personalbusiness256sslcom", product: "personal-business", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: nil},
  {reseller_tier_id: nil, title: "Personal Pro", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Personal Pro", "points"=>"", "validation_level"=>"class 2", "summary"=>"for authenticating and encrypting email and well as client services", "abbr"=>"Personal Pro"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "personalpro256sslcom", product: "personal-pro", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: nil},
  {reseller_tier_id: nil, title: "Personal Enterprise", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Personal Enterprise", "points"=>"", "validation_level"=>"class 2", "summary"=>"for authenticating and encrypting email and well as client services", "abbr"=>"Personal Enterprise"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "personalenterprise256sslcom", product: "personal-enterprise", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: nil},
  {reseller_tier_id: nil, title: "Document Signing", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"Document Signing", "points"=>"<div class='check'>Legally binding and complies with the U.S. Federal ESIGN Act</div>\n                         <div class='check'>Stored on USB etoken for 2 factor authentication</div>\n                         <div class='check'>No required plugins or software</div>\n                         <div class='check'>Customizable appearance of digital signature</div>\n                         <div class='check'>Shows signed by a person OR department</div>\n                         <div class='check'>30 day money-back guaranty </div>\n                         <div class='check'>24 hour 5-star support</div>", "validation_level"=>"basic", "summary"=>"for signing and authenticating documents such as Adobe pdf, Microsoft Office, OpenOffice and LibreOffice", "abbr"=>"Document Signing"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "documentsigning256sslcom", product: "document-signing", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: nil},
  {reseller_tier_id: nil, title: "NAESB Basic", status: "live", summary: nil, text_only_summary: nil, description: {"certificate_type"=>"NAESB Basic", "points"=>"<div class='check'>Requirorders_helper.rb:178ed for NAESB EIR and etag authentication</div>\n                         <div class='check'>User for wesbsite authentication</div>\n                         <div class='check'>Issued from SSL.com ACA</div>\n                         <div class='check'>2048 bit public key encryption</div>\n                         <div class='check'>quick issuance</div>\n                         <div class='check'>30 day money-back guaranty </div>\n                         <div class='check'>24 hour 5-star support</div>", "validation_level"=>"basic", "summary"=>"for authenticating and encrypting email and well as client services", "abbr"=>"NAESB Basic"}, text_only_description: nil, allow_wildcard_ucc: nil, published_as: "live", serial: "naesbbasic256sslcom", product: "personal-naesb-basic", icons: {"main"=>"gold_lock_lg.gif"}, display_order: {"all"=>3, "index"=>2}, roles: "Registered", special_fields: ["entity_code"]}
])
