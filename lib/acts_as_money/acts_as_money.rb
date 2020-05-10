require 'money'

module CollectiveIdea
  module Acts
    module Money
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def money(name, options = {})
          options = {:cents => :cents, :currency => :currency}.merge(options)
          mapping = [[options[:cents].to_s, 'cents']]
          mapping << [options[:currency].to_s, 'currency'] if options[:currency]

          composed_of name, :class_name => 'Money', :allow_nil => true, :mapping => mapping do |m|
            ::Money.new(m.to_f*100)
          end
        end
      end
    end
  end
end
