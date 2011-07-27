class CreateCertificateContents < ActiveRecord::Migration
  def self.up
    create_table :certificate_contents, force: true do |t|
      t.references  :certificate_order, :null => false
      t.text        :signing_request, :null => false
      t.text        :signed_certificate
      t.references  :server_software
      t.text        :domains
      t.integer     :duration
      t.string      :workflow_state
      t.boolean     :billing_checkbox, :validation_checkbox, :technical_checkbox
      t.timestamps
    end
  end

  def self.down
    drop_table  :certificate_contents
  end
end
