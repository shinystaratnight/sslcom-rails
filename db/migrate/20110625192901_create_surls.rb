class CreateSurls < ActiveRecord::Migration
  def self.up
    create_table :surls do |t|
      t.references :user
      t.text      :original
      t.string    :identifier
      t.string    :username
      t.string    :crypted_password                                   # optional, see below
      t.string    :password_salt                                      # optional, but highly recommended
      t.boolean   :require_ssl
      t.string    :status

      t.timestamps
    end
  end

  def self.down
    drop_table :surls
  end
end