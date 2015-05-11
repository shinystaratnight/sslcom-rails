class CreateCanCanPermissions < ActiveRecord::Migration
  def self.up
    add_column :roles, :ssl_account_id, :integer
    add_column :roles, :description, :text
    add_column :roles, :status, :string

    create_table :permissions, force: true do |t|
      t.string  :name
      t.string  :action
      t.string  :subject_class
      t.integer :subject_id
      t.text    :description
      t.timestamps
    end

    create_table :permissions_roles, force: true do |t|
      t.references :permission
      t.references :role
      t.timestamps
    end
  end

  def self.down
    remove_column :roles, :ssl_account_id
    remove_column :roles, :description
    remove_column :roles, :status

    drop_table :permissions
    drop_table :permissions_roles
  end
end
