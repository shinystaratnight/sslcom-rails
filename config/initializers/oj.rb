# frozen_string_literal: true

require 'active_support/core_ext'
require 'active_support/json'
require 'oj'

Oj.optimize_rails

tracer = TracePoint.new(:raise) do |tp|
  p [tp.lineno, tp.event, tp.raised_exception]
end

tracer.enable { Time.zone.now.to_json }
