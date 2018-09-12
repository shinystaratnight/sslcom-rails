class AddIndexesToCertificateNames < ActiveRecord::Migration
  def change
    add_index :certificate_names, [:certificate_content_id]
    add_index :certificate_names, [:name]
    add_index :orders, [:state,:description,:notes]
    add_index :funded_accounts, [:ssl_account_id]
    add_index :certificate_contents, [:ref]
    add_index :system_audits, [:target_id,:target_type]
    add_index :system_audits, [:owner_id,:owner_type]
    add_index :system_audits, [:target_id,:target_type,:owner_id,:owner_type],
              :name => 'index_system_audits_on_4_cols'
    add_index :domain_control_validations, [:certificate_name_id,:email_address,:dcv_method],
              :name => 'index_domain_control_validations_on_3_cols'
    add_index :domain_control_validations, [:csr_id,:email_address,:dcv_method],
              :name => 'index_domain_control_validations_on_3_cols(2)'
  end
end
