class CreateCdns < ActiveRecord::Migration
  def change
    create_table :cdns do |t|
      t.references :ssl_account
      t.string :api_key
      t.timestamps null: false
    end
  end
end
