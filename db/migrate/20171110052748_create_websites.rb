class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string      :host,:api_host,:name,:description,:type
      t.references  :db
      t.integer     :sandbox_db_id
    end
  end
end
