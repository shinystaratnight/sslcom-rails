class CreateSurls < ActiveRecord::Migration
  def self.up
    create_table :surls do |t|
      t.text      :original
      t.string    :crypted_password                                   # optional, see below
      t.string    :password_salt                                      # optional, but highly recommended

      t.timestamps
    end
  end

  def self.down
    drop_table :surls
  end
end
