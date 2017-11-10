class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string      :host,:api_host,:name,:description,:type
      t.references  :db
    end
  end
end
