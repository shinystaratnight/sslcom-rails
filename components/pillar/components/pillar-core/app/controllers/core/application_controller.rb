module Pillar
  module Core
    class ApplicationController < ActionController::Base
      include Pillar::Core::CommonController

      def show
        render "default/component_details"
      end
    end
  end
end
