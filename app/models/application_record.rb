# frozen_string_literal: true

require 'acts_as_billable/lib/active_merchant_default_gateway'
require 'acts_as_billable/lib/acts_as_sellable'
require 'acts_as_billable/lib/acts_as_seller'
require 'acts_as_billable/lib/acts_as_billable'

require 'acts_as_money/aggregations'
require 'acts_as_money/acts_as_money'

require 'acts_as_notable/lib/notable_methods'
require 'acts_as_notable/lib/note_methods'

require 'acts_as_publishable/lib/acts_as_publishable'

class ApplicationRecord < ActiveRecord::Base
  include Swagger::Blocks
  include CollectiveIdea::Acts::Billable
  include CollectiveIdea::Acts::Sellable
  include CollectiveIdea::Acts::Money
  include Acts::As::Publishable

  self.abstract_class = true

  def to_param
    ref
  end
end
