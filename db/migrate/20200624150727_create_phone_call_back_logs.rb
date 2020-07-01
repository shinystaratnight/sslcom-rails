class CreatePhoneCallBackLogs < ActiveRecord::Migration
  def change
    create_table :phone_call_back_logs do |t|
      t.string :validated_by, null: false
      t.string :cert_order_ref, null: false
      t.string :phone_number, null: false
      t.datetime :validated_at, null: false
      t.timestamps null: false
    end unless table_exists?(:phone_call_back_logs)

    add_reference :phone_call_back_logs, :certificate_order, foreign_key: true
  end
end
