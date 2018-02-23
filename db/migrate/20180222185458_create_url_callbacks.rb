class CreateUrlCallbacks < ActiveRecord::Migration
  def change
    create_table :url_callbacks do |t|
      t.references  :callbackable, polymorphic: true
      t.string :url
      t.string :method
      t.text :auth
      t.text :headers
      t.text :parameters
      t.timestamps
    end
  end
end
