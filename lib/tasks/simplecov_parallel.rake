# frozen_string_literal: true

if Rails.env.test?
  require_relative "../../test/simplecov_helper"
  namespace :simplecov do
    desc "merge_results"
    task report_coverage: :environment do
      SimpleCovHelper.report_coverage
    end
  end
end
