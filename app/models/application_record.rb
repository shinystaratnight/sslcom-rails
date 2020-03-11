# frozen_string_literal: true

require 'acts_as_money/aggregations'
require 'acts_as_money/acts_as_money'

# require 'acts_as_notable/lib/notable_methods'
# require 'acts_as_notable/lib/note_methods'

# require 'acts_as_publishable/lib/acts_as_publishable'

class ApplicationRecord < ActiveRecord::Base
  include ActiveModel::Dirty
  # include Swagger::Blocks
  # include CollectiveIdea::Acts::Sellable
  include CollectiveIdea::Acts::Money
  # include Acts::As::Publishable

  self.abstract_class = true

  def model_and_id
    [self.class.to_s.underscore, id].join('_')
  end
end
