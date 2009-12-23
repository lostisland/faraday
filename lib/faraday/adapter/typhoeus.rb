module Faraday
  module Adapter
    module Typhoeus
      extend Faraday::Connection::Options

      begin
        require 'typhoeus'

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
        
        def _post(uri, data, request_headers)
          _perform(:post, uri, :headers => request_headers, :params => data)
        end

        def _get(uri, request_headers)
          _perform(:get, uri, :headers => request_headers)
        end

        def _put(uri, data, request_headers)
          _perform(:put, uri, :headers => request_headers, :params => data)
        end

        def _delete(uri, request_headers)
          _perform(:delete, uri, :headers => request_headers)
        end

        def _perform method, uri, params
          response_class.new do |resp|
            is_async = in_parallel?
            setup_parallel_manager
            params[:method] = method
            req      = ::Typhoeus::Request.new(uri.to_s, params)
            req.on_complete do |response|
              raise Faraday::Error::ResourceNotFound if response.code == 404
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
          Hash[*header_string.split(/\r\n/).
            tap  { |a|      a.shift           }. # drop the HTTP status line
            map! { |h|      h.split(/:\s+/,2) }. # split key and value
            map! { |(k, v)| [k.downcase, v]   }.flatten!]
        end
      rescue LoadError => e
        self.load_error = e
      end
    end
  end
end
