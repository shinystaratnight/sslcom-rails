class AddUniqueValueToDcv < ActiveRecord::Migration
  def change
    add_reference :domain_control_validations, :csr_unique_value
  end
end
