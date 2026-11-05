# frozen_string_literal: true

RSpec.describe Faraday::SSLOptions do
  let(:members) do
    %i[verify verify_hostname hostname ca_file ca_path verify_mode
       cert_store client_cert client_key certificate private_key
       verify_depth version min_version max_version ciphers]
  end

  it 'inherits from BaseOptions' do
    expect(described_class.superclass).to eq(Faraday::BaseOptions)
    expect(described_class.new).to be_a(Faraday::OptionsLike)
  end

  it 'exposes all the members, in order' do
    expect(described_class::MEMBERS).to eq(members)
    expect(described_class.new.members).to eq(members)
    expect(described_class.members).to eq(members)
  end

  it 'has a reader and a writer for every member' do
    options = described_class.new
    members.each_with_index do |member, index|
      options.public_send(:"#{member}=", index)
      expect(options.public_send(member)).to eq(index)
    end
  end

  describe '.from' do
    it 'works with nil' do
      options = described_class.from(nil)
      expect(options).to be_a(described_class)
      expect(options.to_hash).to eq({})
      expect(options.inspect).to eq('#<Faraday::SSLOptions (empty)>')
    end

    it 'works with a hash' do
      options = described_class.from(verify: false, ca_file: 'ca.pem')
      expect(options.verify).to be(false)
      expect(options.ca_file).to eq('ca.pem')
    end

    it 'works with string keys' do
      options = described_class.from('verify_hostname' => false, 'ciphers' => 'HIGH')
      expect(options.verify_hostname).to be(false)
      expect(options.ciphers).to eq('HIGH')
    end

    it 'works with a legacy Options' do
      legacy = Faraday::Options.new(:verify, :ca_file).new(false, 'ca.pem')
      options = described_class.from(legacy)
      expect(options).to be_a(described_class)
      expect(options.to_hash).to eq(verify: false, ca_file: 'ca.pem')
    end

    it 'returns a copy of an instance' do
      original = described_class.new(verify: false)
      copy = described_class.from(original)
      expect(copy).to be_a(described_class)
      expect(copy).not_to equal(original)
      expect(copy.verify).to be(false)
    end

    it 'raises for an unsupported value' do
      expect { described_class.from(1) }.to raise_error(ArgumentError)
    end

    it 'raises for an unknown key' do
      expect { described_class.from(foo: 1) }.to raise_error(NoMethodError)
    end
  end

  describe '#initialize' do
    it 'accepts keyword arguments' do
      options = described_class.new(verify: false, min_version: :TLS1_2)
      expect(options.verify).to be(false)
      expect(options.min_version).to eq(:TLS1_2)
    end

    it 'does not build a cert_store' do
      expect(described_class.new(ca_file: 'ca.pem').cert_store).to be_nil
    end
  end

  describe 'predicates' do
    it 'verifies unless verify is false' do
      expect(described_class.new).to be_verify
      expect(described_class.new(verify: true)).to be_verify
      expect(described_class.new(verify: nil)).to be_verify
      expect(described_class.new(verify: :none)).to be_verify
      expect(described_class.new(verify: false)).not_to be_verify
    end

    it 'is disabled when verify is false' do
      expect(described_class.new).not_to be_disable
      expect(described_class.new(verify: false)).to be_disable
    end

    it 'verifies the hostname unless verify_hostname is false' do
      expect(described_class.new).to be_verify_hostname
      expect(described_class.new(verify_hostname: true)).to be_verify_hostname
      expect(described_class.new(verify_hostname: false)).not_to be_verify_hostname
    end
  end

  describe '#update' do
    it 'overwrites with false but not with nil' do
      options = described_class.new(verify: true, ca_file: 'ca.pem')
      options.update(verify: false, ca_file: nil)
      expect(options.verify).to be(false)
      expect(options.ca_file).to eq('ca.pem')
    end
  end

  describe '#merge' do
    it 'does not modify the receiver' do
      options = described_class.new(verify: true, ca_file: 'ca.pem')
      merged = options.merge(verify: false, version: 'TLSv1')
      expect(merged.to_hash).to eq(verify: false, ca_file: 'ca.pem', version: 'TLSv1')
      expect(options.to_hash).to eq(verify: true, ca_file: 'ca.pem')
    end

    it 'accepts another instance' do
      merged = described_class.new(verify: true).merge(described_class.new(ca_file: 'ca.pem'))
      expect(merged.to_hash).to eq(verify: true, ca_file: 'ca.pem')
    end
  end

  describe '#merge!' do
    it 'updates the receiver' do
      options = described_class.new(verify: true)
      expect(options.merge!(ca_file: 'ca.pem', verify: nil)).to equal(options)
      expect(options.to_hash).to eq(verify: true, ca_file: 'ca.pem')
    end
  end

  describe '#deep_dup' do
    it 'creates an independent copy' do
      options = described_class.new(verify: true, ciphers: 'HIGH')
      copy = options.deep_dup
      copy.verify = false
      expect(copy).to be_a(described_class)
      expect(options.verify).to be(true)
      expect(copy.ciphers).to eq('HIGH')
    end

    it 'shares the cert_store and the certificates' do
      store = OpenSSL::X509::Store.new
      options = described_class.new(cert_store: store)
      expect(options.deep_dup.cert_store).to equal(store)
    end
  end

  describe '#dup' do
    it 'is a shallow copy' do
      options = described_class.new(verify: true)
      copy = options.dup
      copy.verify = false
      expect(options.verify).to be(true)
    end
  end

  describe '#to_hash' do
    it 'skips nil members and keeps false' do
      options = described_class.new(verify: false, ca_file: 'ca.pem')
      expect(options.to_hash).to eq(verify: false, ca_file: 'ca.pem')
    end
  end

  describe '#inspect' do
    it 'lists the members that are set, skipping false like the legacy Options' do
      options = described_class.new(verify: false, ca_file: 'ca.pem')
      expect(options.inspect).to eq('#<Faraday::SSLOptions ca_file="ca.pem">')
      expect(described_class.new(verify: false).inspect).to eq('#<Faraday::SSLOptions (empty)>')
    end
  end

  describe 'Struct-style API used by adapters, see StructCompat' do
    subject(:options) { described_class.new(verify: false, ca_file: 'ca.pem') }

    it 'is kept for the whole 2.x series' do
      expect(options).to be_a(Faraday::StructCompat)
      expect(options).to be_a(Faraday::Options)
    end

    it 'reads and writes the members' do
      expect(options[:ca_file]).to eq('ca.pem')
      expect(options['verify']).to be(false)
      options[:ca_path] = '/certs'
      expect(options.ca_path).to eq('/certs')
      expect { options[:foo] }.to raise_error(NameError)
    end

    it 'goes through overridden accessors' do
      klass = Class.new(described_class) do
        def ca_file
          'overridden'
        end
      end
      expect(klass.new(ca_file: 'ca.pem')[:ca_file]).to eq('overridden')
    end

    it 'fetches members the way adapters do' do
      expect(options.fetch(:verify, true)).to be(false)
      expect(options.fetch(:verify_hostname, false)).to be(false)
      expect(options.verify_hostname).to be(false)
    end

    it 'lists the set members' do
      expect(options.keys).to eq(%i[verify ca_file])
      expect(options.key?(:verify)).to be(true)
      expect(options.key?(:ca_path)).to be(false)
      expect(options.to_h.keys).to eq(members)
    end

    it 'builds from positional arguments, like a Struct' do
      expect(described_class.new(true).verify).to be(true)
      expect(described_class.new(false, false).verify_hostname).to be(false)
      expect(described_class.new(false)).not_to be_verify
    end

    it 'builds an empty instance from a falsy value' do
      expect(described_class.from(false).to_hash).to eq({})
    end
  end

  describe 'interoperability with legacy Options' do
    it 'is coerced by ConnectionOptions' do
      options = Faraday::ConnectionOptions.from(ssl: { verify: false })
      expect(options.ssl).to be_a(described_class)
      expect(options.ssl.verify).to be(false)
    end

    it 'is built by default by ConnectionOptions' do
      expect(Faraday::ConnectionOptions.new.ssl).to be_a(described_class)
    end

    it 'is copied by ConnectionOptions.from' do
      ssl = described_class.new(verify: false)
      options = Faraday::ConnectionOptions.from(ssl: ssl)
      expect(options.ssl).to be_a(described_class)
      expect(options.ssl).not_to equal(ssl)
      expect(options.ssl.verify).to be(false)
    end

    it 'is merged by ConnectionOptions#merge!' do
      options = Faraday::ConnectionOptions.from(ssl: { verify: false, ca_file: 'ca.pem' })
      options.merge!(ssl: { verify: true }) # rubocop:disable Performance/RedundantMerge
      expect(options.ssl).to be_a(described_class)
      expect(options.ssl.to_hash).to eq(verify: true, ca_file: 'ca.pem')
    end

    it 'is deep merged into by Utils.deep_merge' do
      options = Faraday::ConnectionOptions.from(ssl: { ca_file: 'ca.pem' })
      merged = Faraday::Utils.deep_merge(options, ssl: { verify: false })
      expect(merged.ssl).to be_a(described_class)
      expect(merged.ssl.to_hash).to eq(verify: false, ca_file: 'ca.pem')
      expect(options.ssl.verify).to be_nil
    end

    it 'is shared with the Connection and its Env' do
      conn = Faraday.new(ssl: { verify: false, ca_file: 'ca.pem' })
      expect(conn.ssl).to be_a(described_class)
      env = Faraday::Request.create(:get).to_env(conn)
      expect(env.ssl).to equal(conn.ssl)
      expect(env[:ssl].fetch(:verify, true)).to be(false)
    end

    it 'is duplicated by Connection#dup' do
      conn = Faraday.new(ssl: { verify: false })
      copy = conn.dup
      copy.ssl.verify = true
      expect(copy.ssl).to be_a(described_class)
      expect(conn.ssl.verify).to be(false)
    end
  end
end
