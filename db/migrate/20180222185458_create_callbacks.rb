class CreateCallbacks < ActiveRecord::Migration
  def change
    create_table :callbacks do |t|
      t.references  :callbackable, polymorphic: true
      t.string :url
      t.string :method
      t.string :auth
      t.text :headers
      t.text :parameters
      t.timestamps
    end
  end
end
