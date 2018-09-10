class CreateCertificateOrderTokens < ActiveRecord::Migration
  def change
    create_table :certificate_order_tokens, force: true do |t|
      t.references :certificate_order
      t.references :user
      t.references :ssl_account
      t.string :token
      t.boolean :is_expired
      t.datetime :due_date
      t.timestamps
    end
  end
end
