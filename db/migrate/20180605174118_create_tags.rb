class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string     :name, null: false
      t.references :ssl_account, null: false
      t.integer    :taggings_count, null: false, default: 0
      t.timestamps null: false
    end
    
    add_index :tags, :ssl_account_id
    add_index :tags, :taggings_count
    add_index :tags, [:ssl_account_id, :name]
  end
end
