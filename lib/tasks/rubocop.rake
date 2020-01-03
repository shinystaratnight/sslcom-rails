# frozen_string_literal: true

unless Rails.env.production?
  namespace :rubocop do
    require 'rubocop/rake_task'

    desc 'Run RuboCop on entire project'
    RuboCop::RakeTask.new('all') do |task|
      task.fail_on_error = false
    end

    desc 'Run RuboCop on the project based on git diff(DIFF_BRANCH environment variable)'
    RuboCop::RakeTask.new('git_diff') do |task|
      task.patterns = patterns_for_changed_files
      task.fail_on_error = false
    end

    def changed_files
      diff_branch = ENV['DIFF_BRANCH'] || 'staging'
      cmd = %(git diff-tree -r --no-commit-id --diff-filter=M --name-only HEAD origin/#{diff_branch})
      diff = `#{cmd}`
      diff.gsub!(/^(db\/|vendor\/|tmp\/|lib\/|test\/|bin\/|config\/|scripts\/|features\/)+\S+/, '')
      diff.split "\n"
    end

    def patterns_for_changed_files
      patterns = []
      patterns + changed_files
    end
  end
end
