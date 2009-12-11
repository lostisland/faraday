require 'typhoeus'
module Faraday
  module Adapter
    module Typhoeus
      def in_parallel?
        !!@parallel_manager
      end

      def in_parallel(options = {})
        setup_parallel_manager(options)
        yield
        run_parallel_requests
      end

      def setup_parallel_manager(options = {})
        @parallel_manager ||= ::Typhoeus::Hydra.new(options)
      end

      def run_parallel_requests
        @parallel_manager.run
        @parallel_manager = nil
      end

      def _get(uri, request_headers)
        response_class.new do |resp|
          is_async = in_parallel?
          setup_parallel_manager
          req      = ::Typhoeus::Request.new(uri.to_s, :headers => request_headers, :method => :get)
          req.on_complete do |response|
            resp.process!(response.body)
            resp.headers = parse_response_headers(response.headers)
          end
          @parallel_manager.queue(req)
          if !is_async then run_parallel_requests end
        end
      rescue Errno::ECONNREFUSED
        raise Faraday::Error::ConnectionFailed, "connection refused"
      end

      def parse_response_headers(header_string)
        return {} if !header_string || header_string.empty?
        Hash[*header_string.split(/\r\n/).
          tap  { |a|      a.shift           }. # drop the HTTP status line
          map! { |h|      h.split(/:\s+/,2) }. # split key and value
          map! { |(k, v)| [k.downcase, v]   }.flatten!]
      end
    end
  end
end
