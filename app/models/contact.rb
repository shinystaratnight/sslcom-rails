class Contact < ActiveRecord::Base
  belongs_to  :contactable, :polymorphic => true
  include V2MigrationProgressAddon

  EXCLUDED_FIELDS = %w(id roles type contactable_id contactable_type created_at updated_at notes)

  def to_api_query
    attributes.except(*EXCLUDED_FIELDS)
  end
end
