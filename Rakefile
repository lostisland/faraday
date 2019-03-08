# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rspec_junit_formatter'

RSpec::Core::RakeTask.new(:spec) do |config|
  config.rspec_opts = '--format progress --format RspecJunitFormatter --out ~/test-results/rspec/results.xml' if ENV['CI']
end

task default: :spec
