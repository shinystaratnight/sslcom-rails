module Pillar
  module Authority
    class ApplicationController < ActionController::Base
      include Pillar::Core::CommonController
      
      def show
        render "default/component_details"
      end
    end
  end
end
