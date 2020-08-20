class SystemAudit < ApplicationRecord
  belongs_to  :owner, polymorphic: true
  belongs_to  :target, polymorphic: true
end
