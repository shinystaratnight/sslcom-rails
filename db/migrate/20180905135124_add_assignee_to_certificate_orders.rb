class AddAssigneeToCertificateOrders < ActiveRecord::Migration
  def change
    add_reference :certificate_orders, :assignee, references: :users
  end
end
