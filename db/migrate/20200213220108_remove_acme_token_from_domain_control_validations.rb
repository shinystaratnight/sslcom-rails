class RemoveAcmeTokenFromDomainControlValidations < ActiveRecord::Migration
  def change
    remove_column :domain_control_validations, :acme_token
  end
end
