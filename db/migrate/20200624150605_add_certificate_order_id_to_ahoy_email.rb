class AddCertificateOrderIdToAhoyEmail < ActiveRecord::Migration
  def up
     add_reference :ahoy_messages, :certificate_order, foreign_key: true
   end

   def down
     remove_reference :ahoy_messages, :certificate_order
   end
end
