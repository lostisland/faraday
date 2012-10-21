module Faraday
  # Subclasses Struct with some special helpers for converting from a Hash to
  # a Struct.
  class Options < Struct
    def self.from(value)
      value ? new.update(value) : new
    end

    def self.options(mapping)
      attribute_options.update(mapping)
    end

    def self.options_for(key)
      attribute_options[key]
    end

    def self.attribute_options
      @attribute_options ||= {}
    end

    def each(&block)
      members.each do |key|
        block.call key, send(key)
      end
    end

    def update(obj)
      obj.each do |key, value|
        sub_options = self.class.options_for(key)
        if sub_options && value
          value = sub_options.from(value)
        elsif Hash === value
          hash = {}
          value.each do |hash_key, hash_value|
            hash[hash_key] = hash_value
          end
          value = hash
        end

        self.send("#{key}=", value)
      end
      self
    end

    def merge(value)
      dup.update(value)
    end

    def fetch(key, default = nil)
      send(key) || send("#{key}=", default ||
        (block_given? ? Proc.new.call : nil))
    end

    def values_at(*keys)
      keys.map { |key| send(key) }
    end
  end

  class RequestOptions < Options.new(:params_encoder, :oauth, :bind,
    :timeout, :open_timeout, :boundary,
    :custom, :proxy)

    def params_encoder
      self[:params_encoder] ||= NestedParamsEncoder
    end
  end

  class SSLOptions < Options.new(:verify, :ca_file, :ca_path,
    :cert_store, :client_cert, :client_key, :verify_depth, :version)

    def verify?
      verify != false
    end

    def disable?
      !verify?
    end
  end

  class ProxyOptions < Options.new(:uri, :user, :password)
    extend Forwardable
    def_delegators :uri, :scheme, :scheme=, :host, :host=, :port, :port=

    def self.from(value)
      case value
      when String then value = {:uri => Connection.URI(value)}
      when URI then value = {:uri => value}
      end
      super(value)
    end

    def uri
      @uri ||= Connection.URI(self[:uri])
    end

    def user
      self[:user] ||= Utils.unescape(uri.user)
    end

    def password
      self[:password] ||= Utils.unescape(uri.password)
    end
  end

  class ConnectionOptions < Options.new(:request, :proxy, :ssl, :builder, :url,
    :parallel_manager, :params, :headers)

    options :request => RequestOptions, :ssl => SSLOptions

    def request
      self[:request] ||= self.class.options_for(:request).new
    end

    def ssl
      self[:ssl] ||= self.class.options_for(:ssl).new
    end
  end

  class Env < Options.new(:method, :body, :url, :request, :request_headers,
    :ssl, :parallel_manager, :params, :response, :response_headers, :status)

    options :request => ConnectionOptions,
      :request_headers => Utils::Headers, :response_headers => Utils::Headers
  end
end

