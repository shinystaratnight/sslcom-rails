class CreateShoppingCart < ActiveRecord::Migration
  def self.up
    create_table :shopping_carts, force: true do |t|
      t.references  :user
      t.string      :guid
      t.text        :content
      t.string      :token
      t.string      :crypted_password                                   # optional, see below
      t.string      :password_salt                                      # optional, but highly recommended
      t.string      :access
      t.timestamps
    end
  end

  def self.down
    drop_table :shopping_carts
  end
end
