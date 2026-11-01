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
    it 'lists the set members' do
      options = described_class.new(verify: false, ca_file: 'ca.pem')
      expect(options.inspect).to eq('#<Faraday::SSLOptions verify=false, ca_file="ca.pem">')
    end
  end

  describe 'Struct-style access used by adapters' do
    subject(:options) { described_class.new(verify: false, ca_file: 'ca.pem') }

    it 'reads members with []' do
      expect(options[:ca_file]).to eq('ca.pem')
      expect(options['verify']).to be(false)
      expect(options[:ca_path]).to be_nil
    end

    it 'writes members with []=' do
      options[:ca_path] = '/certs'
      options['verify'] = true
      expect(options.ca_path).to eq('/certs')
      expect(options.verify).to be(true)
    end

    it 'raises NameError for an unknown member' do
      expect { options[:foo] }.to raise_error(NameError)
      expect { options[:foo] = 1 }.to raise_error(NameError)
    end

    it 'goes through overridden accessors' do
      klass = Class.new(described_class) do
        def ca_file
          'overridden'
        end
      end
      expect(klass.new(ca_file: 'ca.pem')[:ca_file]).to eq('overridden')
    end

    describe '#fetch' do
      it 'returns false members' do
        expect(options.fetch(:verify, true)).to be(false)
      end

      it 'sets and returns the default for a nil member' do
        expect(options.fetch(:verify_hostname, false)).to be(false)
        expect(options.verify_hostname).to be(false)
      end

      it 'sets and returns the block value for a nil member' do
        expect(options.fetch(:version, &:to_s)).to eq('version')
        expect(options.version).to eq('version')
      end

      it 'raises KeyError without a default for a nil member' do
        expect { options.fetch(:version) }.to raise_error(KeyError)
      end

      it 'raises for an unknown member' do
        expect { options.fetch(:foo, 1) }.to raise_error(NoMethodError)
      end
    end

    it 'lists the set members with #keys' do
      expect(options.keys).to eq(%i[verify ca_file])
    end

    it 'checks the set members with #key?' do
      expect(options.key?(:verify)).to be(true)
      expect(options.has_key?(:ca_file)).to be(true) # rubocop:disable Style/PreferredHashMethods
      expect(options.key?(:ca_path)).to be(false)
      expect(options.key?(:foo)).to be(false)
    end

    it 'tells if it is empty' do
      expect(options).not_to be_empty
      expect(described_class.new).to be_empty
    end

    it 'lists all the values, set or not' do
      expect(options.values.size).to eq(members.size)
      expect(options.values.compact).to eq([false, 'ca.pem'])
      expect(options.values_at(:ca_file, :ca_path)).to eq(['ca.pem', nil])
      expect(options.value?('ca.pem')).to be(true)
      expect(options.has_value?('other')).to be(false) # rubocop:disable Style/PreferredHashMethods
    end

    it 'enumerates all the members' do
      pairs = options.each.to_a
      expect(pairs.map(&:first)).to eq(members)
      expect(pairs.to_h).to include(verify: false, ca_file: 'ca.pem', ca_path: nil)
      expect(options.each_key.to_a).to eq(%i[verify ca_file])
      expect(options.each_value.to_a).to eq(options.values)
    end

    it 'converts to a hash with all the members' do
      expect(options.to_h.keys).to eq(members)
      expect(options.to_h).to include(verify: false, ca_file: 'ca.pem', ca_path: nil)
    end

    it 'digs into the members' do
      options.client_cert = { subject: ['cn'] }
      expect(options.dig(:client_cert, :subject, 0)).to eq('cn')
    end

    it 'deletes a member' do
      expect(options.delete(:ca_file)).to eq('ca.pem')
      expect(options.ca_file).to be_nil
    end

    it 'clears all the members' do
      options.clear
      expect(options).to be_empty
    end

    it 'builds a set of the set members' do
      expect(options.symbolized_key_set).to eq(Set[:verify, :ca_file])
    end

    it 'compares by value' do
      expect(options).to eq(described_class.new(verify: false, ca_file: 'ca.pem'))
      expect(options).to eql(described_class.new(verify: false, ca_file: 'ca.pem'))
      expect(options.hash).to eq(described_class.new(verify: false, ca_file: 'ca.pem').hash)
      expect(options).not_to eq(described_class.new(verify: false))
      expect(options).not_to eq(verify: false, ca_file: 'ca.pem')
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
