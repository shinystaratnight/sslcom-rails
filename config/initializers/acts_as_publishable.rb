require 'acts_as_publishable/lib/acts_as_publishable'
ActiveRecord::Base.send(:include, Acts::As::Publishable)
