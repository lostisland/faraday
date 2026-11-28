# frozen_string_literal: true

# Counts the objects that each case in bench/cases.rb allocates per call, and
# compares the counts with bench/allocations.yml.
#
#   bundle exec rake bench:allocations          # fails if a count went up
#   bundle exec rake bench:allocations:update   # writes the new counts
#
# The counts are the same on every run of the same Ruby version, but differ
# between Ruby versions. The baseline records the Ruby version it was made
# with, and the check is skipped on another one.
require 'faraday'
require 'yaml'
require_relative 'cases'

module FaradayBench
  # Allocation counts per call, and the check against the baseline.
  module Allocations
    BASELINE = File.expand_path('allocations.yml', __dir__)
    ITERATIONS = 200

    module_function

    def ruby_version
      RUBY_VERSION.split('.').first(2).join('.')
    end

    def count(callable)
      ITERATIONS.times { callable.call } # warm up memoized state and caches
      GC.start
      GC.disable
      before = GC.stat(:total_allocated_objects)
      ITERATIONS.times { callable.call }
      (GC.stat(:total_allocated_objects) - before).fdiv(ITERATIONS).round
    ensure
      GC.enable
    end

    def measure
      CASES.transform_values { |callable| count(callable) }
    end

    def update
      File.write(BASELINE, YAML.dump('ruby' => ruby_version, 'allocations' => measure))
      puts "Wrote #{BASELINE} for Ruby #{ruby_version}"
    end

    def passes?
      baseline = YAML.safe_load_file(BASELINE)
      if baseline['ruby'] != ruby_version
        puts "Skipped: the baseline is for Ruby #{baseline['ruby']}, this is Ruby #{ruby_version}"
        return true
      end

      within_baseline?(baseline['allocations'], measure)
    end

    def within_baseline?(expected, actual)
      puts 'case                                          baseline      now'
      more = actual.select { |name, count| expected[name] && count > expected[name] }
      actual.each { |name, count| puts row(name, expected[name], count) }
      if more.any?
        puts 'Allocations went up. If that is intended, run bench:allocations:update and commit the baseline.'
      end
      more.empty?
    end

    def row(name, base, count)
      status = if base.nil? then 'new, run bench:allocations:update'
               elsif count > base then 'MORE'
               elsif count < base then 'fewer, run bench:allocations:update'
               end
      format('%-45<name>s %8<base>s %8<count>d %<status>s', name: name, base: base || '-', count: count, status: status)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.include?('--update')
    FaradayBench::Allocations.update
  else
    exit(FaradayBench::Allocations.passes?)
  end
end
