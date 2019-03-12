# frozen_string_literal: true

module Faraday
  class Adapter
    class EMSynchrony < Faraday::Adapter
      # Executes a block in EM if available.
      class EMRunner
        def self.call(&block)
          client = nil

          if EM.reactor_running?
            client = block.call
          else
            EM.run do
              Fiber.new do
                client = block.call
                EM.stop
              end.resume
            end
          end

          client
        end
      end
    end
  end
end
