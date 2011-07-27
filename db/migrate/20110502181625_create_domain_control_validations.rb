class CreateDomainControlValidations < ActiveRecord::Migration
  def self.up
    create_table :domain_control_validations, force: true do |t|
      t.references  :csr
      t.string    :email_address
      t.text      :candidate_addresses
      t.string    :subject
      t.string    :address_to_find_identifier
      t.string    :identifier
      t.boolean   :identifier_found
      t.datetime  :responded_at
      t.datetime  :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :domain_control_validations
  end
end
