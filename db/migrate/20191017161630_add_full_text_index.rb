class AddFullTextIndex < ActiveRecord::Migration
  def change
    add_index :signed_certificates, [:common_name, :url, :body, :decoded, :ext_customer_ref, :ejbca_username],
              name: "index_signed_certificates_cn_u_b_d_ecf_eu", type: :fulltext
    add_index :csrs, [:common_name, :body, :decoded],
              name: "index_csrs_cn_b_d", type: :fulltext
    add_index :certificate_orders, [:ref, :external_order_number, :notes],
              name: "index_certificate_orders_r_eon_n", type: :fulltext
    add_index :ssl_accounts, [:acct_number, :company_name, :ssl_slug],
              name: "index_ssl_accounts_an_cn_ss", type: :fulltext
    add_index :users, [:login, :email],
              name: "index_users_l_e", type: :fulltext
    add_index :contacts, [:first_name, :last_name, :company_name, :department, :po_box, :address1, :address2,
                          :address3, :city, :state, :country, :postal_code, :email, :notes, :assumed_name,
                          :duns_number],
              name: "index_contacts_on_16", type: :fulltext
  end
end
