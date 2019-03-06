# frozen_string_literal: true

require 'rake/testtask'

require 'rspec/core/rake_task'
require 'rspec_junit_formatter'

RSpec::Core::RakeTask.new(:spec) do |config|
  if ENV['CI']
    config.rspec_opts = '--format progress --format RspecJunitFormatter --out ~/test-results/rspec.xml'
  end
end

task default: :test

desc 'Run all tests'
task test: [:spec]
