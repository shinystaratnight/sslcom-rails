class CreateValidationHistories < ActiveRecord::Migration
  def self.up
    create_table :validation_histories, force: true do |t|
      t.references  :validation
      t.string      :reviewer
      t.string      :notes
      t.string      :admin_notes
      t.string      :document_file_name
      t.string      :document_file_size
      t.string      :document_content_type
      t.datetime    :document_updated_at
      t.string      :random_secret
      t.boolean     :publish_to_site_seal
      t.boolean     :publish_to_site_seal_approval, :default=> false
      t.string      :satisfies_validation_methods
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_histories
  end
end
