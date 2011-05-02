class CreateDomainControlValidations < ActiveRecord::Migration
  def self.up
    create_table :domain_control_validations do |t|
      t.references  :csr
      t.string    :email_address
      t.string    :candidate_addresses
      t.string    :subject
      t.datetime  :responded_at
      t.datetime  :sent_at

      t.timestamps
    end
  end

  def self.down
    drop_table :domain_control_validations
  end
end
