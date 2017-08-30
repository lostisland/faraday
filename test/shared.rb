module Faraday
  module Shared
    def self.big_string
      kb = 1024
      (32..126).map{|i| i.chr}.cycle.take(50*kb).join
    end

    def big_string
      Faraday::Shared.big_string
    end
  end
end
