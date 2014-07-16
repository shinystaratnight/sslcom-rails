class AddCertificateNamesToDomainControlValidation < ActiveRecord::Migration
  def self.up
    change_table    :domain_control_validations do |t|
      t.references  :certificate_name
    end
  end

  def self.down
    change_table    :domain_control_validations do |t|
      t.remove      :certificate_name
    end
  end
end
