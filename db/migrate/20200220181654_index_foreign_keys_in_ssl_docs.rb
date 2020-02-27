class IndexForeignKeysInSslDocs < ActiveRecord::Migration
  def change
    add_index :ssl_docs, :folder_id
  end
end
