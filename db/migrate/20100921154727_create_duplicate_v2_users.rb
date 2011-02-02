class CreateDuplicateV2Users < ActiveRecord::Migration
  def self.up
    create_table :duplicate_v2_users do |t|
      t.string :login, :email, :password
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :duplicate_v2_users
  end
end
