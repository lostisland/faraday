# frozen_string_literal: true

# Times each case in bench/cases.rb against the Faraday in FARADAY_LIB (the lib
# folder of a checkout), and prints the median µs per call as JSON.
# bench/compare.rb runs it. It is not meant to be run on its own.
lib = File.expand_path(ENV.fetch('FARADAY_LIB'))
$LOAD_PATH.unshift(lib)
require 'faraday'
require 'json'

loaded = Faraday.method(:new).source_location.first
abort "Loaded Faraday from #{loaded}, not from #{lib}" unless loaded.start_with?(lib)

require_relative 'cases'

module FaradayBench
  # Median time per call, in batches sized to BATCH_SECONDS.
  module Timing
    BATCH_SECONDS = 0.02
    BATCHES = 7

    module_function

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Runs as many calls as fit in BATCH_SECONDS, to size the batches.
    def calibrate(callable)
      iterations = 0
      start = now
      while now - start < BATCH_SECONDS
        callable.call
        iterations += 1
      end
      iterations
    end

    def median_usec(callable)
      iterations = calibrate(callable)
      times = Array.new(BATCHES) do
        start = now
        iterations.times { callable.call }
        (now - start) / iterations * 1_000_000
      end
      times.sort[BATCHES / 2]
    end
  end
end

results = FaradayBench::CASES.to_h do |name, callable|
  [name, FaradayBench::Timing.median_usec(callable)]
rescue StandardError => e
  [name, { 'error' => "#{e.class}: #{e.message}" }]
end
puts JSON.generate('version' => Faraday::VERSION, 'results' => results)
