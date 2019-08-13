class AddCertificateOrderWorkflowIsExpiredIndex < ActiveRecord::Migration
  def change
    add_index :certificate_orders, [:workflow_state,:is_expired]
  end
end
