module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module Sellable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods

        # Declares a model as sellable
        #
        # A sellable model must have a field that stores the price in cents.
        #
        # === Options:
        # * <tt>:cents</tt>: name of cents field (default :cents).
        # * <tt>:currency</tt>: name of currency field (default :currency). Set to <tt>false</tt>
        #   diable storing the currency, causing it to default to USD
        #
        # === Example:
        #
        #   class Product < ActiveRecord::Base
        #     acts_as_sellable :cents => :price_in_cents, :currency => false
        #   end
        #
        def acts_as_sellable(options = {})
          class_eval do
            include InstanceMethods
            money :price, options

            has_many :line_items, :as => :sellable
            has_many :orders, :through => :line_items
          end
        end

        def find_from_model_and_id model_string
          model_and_id = model_string.split(/_(?=\d+$)/)
          model = model_and_id[0].camelize.constantize
          model.find(model_and_id[1].to_i)
        end

        def find_from_model_and_name model_string
          model_and_name = model_string.split('__')
          model = model_and_name[0].camelize.constantize
          model.find_by_name(model_and_name[1])
        end
      end

      module InstanceMethods
      end
    end
  end
end