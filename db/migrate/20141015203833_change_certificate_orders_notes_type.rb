class ChangeCertificateOrdersNotesType < ActiveRecord::Migration
  def up
    change_column :certificate_orders, :notes, :text
  end

  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :certificate_orders, :notes, :string
  end
end
