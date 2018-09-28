class CreateCertificateOrderManagedCsrs < ActiveRecord::Migration
  def change
    create_table :certificate_order_managed_csrs do |t|
      t.references  :certificate_order
      t.references  :managed_csr, references: :csr
      t.timestamps
    end
  end
end
