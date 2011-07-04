class CreateSurls < ActiveRecord::Migration
  def self.up
    create_table :surls do |t|
      t.references :user
      t.text      :original
      t.string    :identifier
      t.string    :guid
      t.string    :username
      t.string    :crypted_password
      t.string    :password_salt
      t.boolean   :require_ssl
      t.boolean   :share
      t.string    :status

      t.timestamps
    end
  end

  def self.down
    drop_table :surls
  end
end
