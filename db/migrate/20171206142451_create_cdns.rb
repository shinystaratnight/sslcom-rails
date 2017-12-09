class CreateCdns < ActiveRecord::Migration
  def change
    create_table :cdns do |t|
      t.references :user
      t.string :api_key
      t.string :host_name
      t.timestamps null: false
    end
  end
end
