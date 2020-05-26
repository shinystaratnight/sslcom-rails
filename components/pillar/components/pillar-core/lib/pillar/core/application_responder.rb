require "responders"

module Pillar
  module Core
    class ApplicationResponder < ActionController::Responder
      # include Responders::FlashResponder
      include Responders::HttpCacheResponder
      include Responders::CollectionResponder
    end
  end
end
