class CreateCertificates < ActiveRecord::Migration
  def self.up
    create_table :certificates do |t|
      t.references  :reseller_tier
      t.string      :title, :status
      t.text        :summary, :text_only_summary, :description,
        :text_only_description
      t.boolean     :allow_wildcard_ucc
      t.string      :published_as, :limit => 16, :default => 'draft'
      t.string      :serial, :unique => true
      t.string      :product
      t.string      :icons
      t.string      :display_order
      t.string      :roles, :default => "--- []"
      t.timestamps
    end
  end

  def self.down
    drop_table  :certificates
  end
end
