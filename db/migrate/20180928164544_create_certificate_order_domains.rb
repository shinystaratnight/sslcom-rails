class CreateCertificateOrderDomains < ActiveRecord::Migration
  def change
    create_table :certificate_order_domains do |t|
      t.references  :certificate_order
      t.references  :domain, references: :certificate_name
    end
  end
end
