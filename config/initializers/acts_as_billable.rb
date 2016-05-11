require 'acts_as_billable/lib/active_merchant_default_gateway'
require 'acts_as_billable/lib/acts_as_sellable'
require 'acts_as_billable/lib/acts_as_seller'
require 'acts_as_billable/lib/acts_as_billable'

ActiveRecord::Base.class_eval do
  include CollectiveIdea::Acts::Billable
  include CollectiveIdea::Acts::Sellable
end
