# frozen_string_literal: true

require 'bundler'

Bundler::GemHelper.install_tasks

# The publish workflow sets FARADAY_RELEASE because its bundle (release/Gemfile) doesn't include RSpec.
unless ENV['FARADAY_RELEASE']
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.ruby_opts = %w[-W]
    # Integration specs need service containers, see .github/workflows/integration-tests.yml
    task.exclude_pattern = 'spec/integration/**/*_spec.rb'
  end

  task default: :spec
end
