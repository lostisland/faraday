# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'bundler'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |task|
  task.ruby_opts = %w[-W]
  # Integration specs need service containers, see .github/workflows/integration-tests.yml
  task.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

task default: :spec
