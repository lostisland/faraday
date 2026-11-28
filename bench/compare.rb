# frozen_string_literal: true

# Compares the speed of two Faraday checkouts on the cases in bench/cases.rb.
#
#   bundle exec rake 'bench:compare[v2.15.1]'   # this checkout against a git ref
#   ruby bench/compare.rb BASE_LIB HEAD_LIB     # two lib folders
#
# Timings on a shared machine (a CI runner, a laptop) vary by 10-30% between
# runs, so the two versions run in alternate rounds (base, head, base, head...)
# on the same machine, and only their ratio counts. A case is flagged when the
# median ratio of the rounds is above 1 + THRESHOLD. The result is a warning,
# not a failure: bench/allocations.rb is the check that fails.
require 'json'
require 'open3'
require 'rbconfig'

module FaradayBench
  # Runs bench/timing.rb on both versions in alternate rounds and compares them.
  module Compare
    ROUNDS = Integer(ENV.fetch('BENCH_ROUNDS', 5))
    THRESHOLD = Float(ENV.fetch('BENCH_THRESHOLD', 0.2))
    TIMING = File.expand_path('timing.rb', __dir__)

    module_function

    def run(lib)
      out, err, status = Open3.capture3({ 'FARADAY_LIB' => lib }, RbConfig.ruby, TIMING)
      abort "bench/timing.rb failed for #{lib}:\n#{err}" unless status.success?
      JSON.parse(out)
    end

    def median(values)
      sorted = values.sort
      mid = sorted.size / 2
      sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
    end

    def compare(base_lib, head_lib)
      rounds = Array.new(ROUNDS) { [run(base_lib), run(head_lib)] }
      versions = rounds.first.map { |run| run['version'] }
      rows = rounds.first.last['results'].keys.map { |name| row(name, rounds) }
      [versions, rows]
    end

    def row(name, rounds)
      pairs = rounds.map { |base, head| [base['results'][name], head['results'][name]] }
      return { name: name, error: pairs.flatten.find { |value| value.is_a?(Hash) } } unless pairs.flatten.all?(Numeric)

      base = median(pairs.map(&:first))
      head = median(pairs.map(&:last))
      ratio = median(pairs.map { |b, h| h / b })
      { name: name, base: base, head: head, ratio: ratio, slower: ratio > 1 + THRESHOLD }
    end

    def markdown(versions, rows)
      lines = ["### Timing: #{versions[1]} (head) against #{versions[0]} (base)", '',
               "Median of #{ROUNDS} alternate rounds, µs per call. Flagged when head is more than " \
               "#{(THRESHOLD * 100).round}% slower.", '',
               '| case | base | head | head / base | |', '|---|---|---|---|---|']
      rows.each do |row|
        lines << if row[:error]
                   "| #{row[:name]} | | | | #{row[:error]&.fetch('error', nil) || 'not measured'} |"
                 else
                   format('| %<name>s | %<base>.1f | %<head>.1f | %<ratio>.2f | %<flag>s |',
                          **row, flag: row[:slower] ? ':warning: slower' : '')
                 end
      end
      lines.join("\n")
    end
  end
end

if $PROGRAM_NAME == __FILE__
  base_lib, head_lib = ARGV
  abort 'Usage: ruby bench/compare.rb BASE_LIB HEAD_LIB' unless base_lib && head_lib

  versions, rows = FaradayBench::Compare.compare(File.expand_path(base_lib), File.expand_path(head_lib))
  report = FaradayBench::Compare.markdown(versions, rows)
  puts report
  File.write(ENV['GITHUB_STEP_SUMMARY'], "#{report}\n", mode: 'a') if ENV['GITHUB_STEP_SUMMARY']
  if ENV['GITHUB_ACTIONS']
    rows.select { |row| row[:slower] }.each do |row|
      puts "::warning title=Slower: #{row[:name]}::#{format('%.2fx the time of the base', row[:ratio])}"
    end
  end
end
