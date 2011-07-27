class CreateCertificateApiRequests < ActiveRecord::Migration
  def self.up
    create_table :certificate_api_requests, force: true do |t|
      t.references :server_software, :country
      t.string :account_key, :secret_key
      t.boolean :test
      t.string :product
      t.integer :period, :server_count
      t.string :other_domains
      t.string :common_names_flag
      t.text :csr
      t.string :organization_name, :post_office_box, :street_address_1 , :street_address_2,
              :street_address_3, :locality_name, :state_or_province_name, :postal_code
      t.string :duns_number, :company_number, :registered_locality_name, :registered_state_or_province_name,
              :registered_country_name, :assumed_name, :business_category,
              :email_address, :contact_email_address, :dcv_email_address, :ca_certificate_id
      t.date  :incorporation_date
      t.boolean :is_customer_validated, :hide_certificate_reference
      t.string :external_order_number, :external_order_number_constraint
      t.string :response

      t.timestamps
    end
  end

  def self.down
    drop_table :certificate_api_requests
  end
end
