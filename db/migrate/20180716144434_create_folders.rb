class CreateFolders < ActiveRecord::Migration
  def change
    create_table :folders do |t|
      t.integer :parent_id, null: true
      t.boolean :default, null: false, default: false
      t.boolean :archive, null: false, default: false
      t.string :name, null: false
      t.string :description
      t.references :ssl_account, null: false, index: true
      t.integer :items_count, default: 0
      t.timestamps null: false
    end
    add_index :folders, [:parent_id]
    add_index :folders, [:name]
    add_column :certificate_orders, :folder_id, :integer
    add_column :ssl_accounts, :default_folder_id, :integer
  end
end
