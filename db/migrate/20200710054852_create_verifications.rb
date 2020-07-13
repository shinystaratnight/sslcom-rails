class CreateVerifications < ActiveRecord::Migration
  def change
    create_table :verifications do |t|
      t.string :sms_number
      t.string :sms_prefix
      t.string :call_number
      t.string :call_prefix
      t.string :email

      t.references :user

      t.timestamps null: false
    end
  end
end
