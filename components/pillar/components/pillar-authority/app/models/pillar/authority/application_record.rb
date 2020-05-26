module Pillar
  module Authority
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
