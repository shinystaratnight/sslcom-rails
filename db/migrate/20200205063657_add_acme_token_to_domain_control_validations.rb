class AddAcmeTokenToDomainControlValidations < ActiveRecord::Migration
  def change
    add_column :domain_control_validations, :acme_token, :string, index: true
  end
end
