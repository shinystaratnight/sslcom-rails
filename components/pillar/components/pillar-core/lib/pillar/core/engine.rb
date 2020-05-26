# frozen_string_literal: true

require "rails/engine"

module Pillar
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Pillar::Core
    end
  end
end
