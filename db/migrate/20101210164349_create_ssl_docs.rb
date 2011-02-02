class CreateSslDocs < ActiveRecord::Migration
  def self.up
    create_table :ssl_docs do |t|
      t.references  :folder
      t.string      :reviewer
      t.string      :notes
      t.string      :admin_notes
      t.string      :document_file_name
      t.string      :document_file_size
      t.string      :document_content_type
      t.datetime    :document_updated_at
      t.string      :random_secret
      t.boolean     :processing
      t.string      :status
      t.string      :display_name
      t.timestamps
    end
  end

  def self.down
    drop_table :ssl_docs
  end
end
