begin
  require 'composite_io'
  require 'parts'
  require 'stringio'
rescue LoadError
  $stderr.puts "Install the multipart-post gem."
  raise
end

module Faraday
  class CompositeReadIO
    def initialize(*parts)
      @parts = parts.flatten
      @ios = @parts.map { |part| part.to_io }
      @index = 0
    end

    def length
      @parts.inject(0) { |sum, part| sum + part.length }
    end

    def rewind
      @ios.each { |io| io.rewind }
      @index = 0
    end

    def read(length = nil, outbuf = nil)
      if length.nil? || length.zero?
        outbuf = outbuf ? outbuf.replace("") : ""
        @ios.inject(outbuf) { |str, io| str << io.read } if length.nil?
        outbuf
      else
        got_result = false
        while part = @ios[@index]
          if result = part.read(length)
            unless got_result
              outbuf = outbuf ? outbuf.replace("") : ""
              got_result = true
            end
            result.force_encoding("BINARY") if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length
            break if length.zero?
          end
          @index += 1
        end
        got_result ? outbuf : nil
      end
    end
  end

  UploadIO = ::UploadIO
  Parts = ::Parts
end
