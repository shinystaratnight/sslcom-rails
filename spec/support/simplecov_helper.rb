# frozen_string_literal: true

require 'active_support/inflector'
require 'simplecov'

class SimpleCovHelper
  def self.report_coverage(base_dir: './coverage_results')
    SimpleCov.start 'rails' do
      filters.clear
      add_filter %r{^/test/}
      add_filter %r{^/spec/}
      add_filter %r{^/.*declarative_authorization.*/}
      add_filter %r{^/.*lib/gems/.*/}
      add_filter %r{^/usr/}
      add_filter %r{^/config/}
      add_filter %r{^/db/}
      add_filter %r{^/vendor/}
      add_filter %r{^/public/}
      add_filter %r{^/features/}
      add_filter %r{^/lib/acts_as}
      add_filter %r{^/lib/in_place_editing}
      add_filter %r{^/lib/dynamic_form}
      add_filter %r{^/lib/preferences}
      add_filter %r{^/app/paths/}
      Dir['app/*'].each do |dir|
        add_group File.basename(dir).humanize, dir
      end

      merge_timeout(3600)
    end
    new(base_dir: base_dir).merge_results
  end

  attr_reader :base_dir

  def initialize(base_dir:)
    @base_dir = base_dir
  end

  def all_results
    Dir["#{base_dir}/.resultset*.json"]
  end

  def merge_results
    results = all_results.map { |file| SimpleCov::Result.from_hash(JSON.parse(File.read(file))) }
    SimpleCov::ResultMerger.merge_results(*results).tap do |result|
      SimpleCov::ResultMerger.store_result(result)
    end
  end
end
