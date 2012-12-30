module Faraday
  # Subclasses Struct with some special helpers for converting from a Hash to
  # a Struct.
  class Options < Struct
    # Public
    def self.from(value)
      value ? new.update(value) : new
    end

    # Public
    def each(&block)
      members.each do |key|
        block.call key.to_sym, send(key)
      end
    end

    # Public
    def update(obj)
      obj.each do |key, value|
        next unless value
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

    # Public
    def delete(key)
      value = send(key)
      send("#{key}=", nil)
      value
    end

    # Public
    def merge(value)
      dup.update(value)
    end

    # Public
    def fetch(key, default = nil)
      send(key) || send("#{key}=", default ||
        (block_given? ? Proc.new.call : nil))
    end

    # Public
    def values_at(*keys)
      keys.map { |key| send(key) }
    end

    # Public
    def keys
      members.reject { |m| send(m).nil? }
    end

    # Public
    def to_hash
      hash = {}
      members.each do |key|
        value = send(key)
        hash[key] = value if value
      end
      hash
    end

    # Internal
    def inspect
      values = []
      members.each do |m|
        value = send(m)
        values << "#{m}=#{value.inspect}" if value
      end
      values = values.empty? ? ' (empty)' : (' ' << values.join(", "))

      %(#<#{self.class}#{values}>)
    end

    # Internal
    def self.options(mapping)
      attribute_options.update(mapping)
    end

    # Internal
    def self.options_for(key)
      attribute_options[key]
    end

    # Internal
    def self.attribute_options
      @attribute_options ||= {}
    end
  end

  class RequestOptions < Options.new(:params_encoder, :proxy, :bind,
    :timeout, :open_timeout, :boundary,
    :oauth)

    def []=(key, value)
      if key && key.to_sym == :proxy
        super(key, value ? ProxyOptions.from(value) : nil)
      else
        super(key, value)
      end
    end
  end

  class SSLOptions < Options.new(:verify, :ca_file, :ca_path, :verify_mode,
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
    def_delegators :uri, :scheme, :scheme=, :host, :host=, :port, :port=, :path, :path=

    def self.from(value)
      case value
      when String then value = {:uri => Connection.URI(value)}
      when URI then value = {:uri => value}
      when Hash, Options
        if uri = value.delete(:uri)
          value[:uri] = Connection.URI(uri)
        end
      end
      super(value)
    end

    def user
      self[:user] ||= Utils.unescape(uri.user)
    end

    def password
      self[:password] ||= Utils.unescape(uri.password)
    end
  end

  class ConnectionOptions < Options.new(:request, :proxy, :ssl, :builder, :url,
    :parallel_manager, :params, :headers, :builder_class)

    options :request => RequestOptions, :ssl => SSLOptions

    def request
      self[:request] ||= self.class.options_for(:request).new
    end

    def ssl
      self[:ssl] ||= self.class.options_for(:ssl).new
    end

    def builder_class
      self[:builder_class] ||= RackBuilder
    end

    def new_builder(block)
      builder_class.new(&block)
    end
  end

  class Env < Options.new(:method, :body, :url, :request, :request_headers,
    :ssl, :parallel_manager, :params, :response, :response_headers, :status)

    ContentLength = 'Content-Length'.freeze
    StatusesWithoutBody = Set.new [204, 304]
    SuccessfulStatuses = 200..299

    # A Set of HTTP verbs that typically send a body.  If no body is set for
    # these requests, the Content-Length header is set to 0.
    MethodsWithBodies = Set.new [:post, :put, :patch, :options]

    options :request => RequestOptions,
      :request_headers => Utils::Headers, :response_headers => Utils::Headers

    extend Forwardable

    def_delegators :request, :params_encoder

    def success?
      SuccessfulStatuses.include?(status)
    end

    def needs_body?
      !body && MethodsWithBodies.include?(method)
    end

    def clear_body
      request_headers[ContentLength] = '0'
      self.body = ''
    end

    def parse_body?
      !StatusesWithoutBody.include?(status)
    end

    def parallel?
      !!parallel_manager
    end
  end
end

