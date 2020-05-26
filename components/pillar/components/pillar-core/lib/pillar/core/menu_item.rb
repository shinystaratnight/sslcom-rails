module Pillar
  module Core
    class MenuItem
      attr_accessor :icon, :component, :title, :group, :path, :link, :order

      def initialize(*args)
        args[0].each do |key, value|
          send("#{key}=", value)
        end
      end
    end
  end
end
