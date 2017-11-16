class Contact < ActiveRecord::Base
  belongs_to  :contactable, :polymorphic => true
  include V2MigrationProgressAddon

  ALIAS_FIELDS = {organization: :company_name, organization_unit: :department,
                  street_address_1: :address1, street_address_2: :address2,
                  street_address_3: :address3, locality: :city, state_or_province: :state, post_office_box: :po_box}
  EXCLUDED_FIELDS = %w(id roles type contactable_id contactable_type created_at updated_at notes)

  ALIAS_FIELDS.each do |k,v|
    alias_attribute k, v
  end

  def to_api_query
    {}.tap do |result|
      (ALIAS_FIELDS.keys+%w(postal_code country email)).each do |k,v|
        result.merge!(k=>self.send(k))
      end
    end
    # attributes.except(*EXCLUDED_FIELDS)
  end
end
