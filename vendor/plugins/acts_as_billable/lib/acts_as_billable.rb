module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module Billable #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_billable
          include CollectiveIdea::Acts::Billable::InstanceMethods
          class_eval do
            has_many :orders, :as => :billable
          end
        end
      end
      
      module InstanceMethods
        def purchase(*sellables)
          sellables = sellables.flatten
          raise ArgumentError.new("Sellable models must have a :price") unless sellables.all? {|sellable| sellable.respond_to? :price }
          returning self.orders.build do |order|
            sellables.each do |sellable|
              li=order.line_items.build :sellable => sellable
            end
          end
        end
      end

    end
  end
end