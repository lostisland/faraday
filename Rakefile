require 'date'
require 'fileutils'
require 'openssl'
require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :test

## helper functions

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  line = File.read("lib/#{name}.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

def gemspec_file
  "#{name}.gemspec"
end

def gem_file
  "#{name}-#{version}.gem"
end

def replace_header(head, header_name)
  head.sub!(/(\.#{header_name}\s*= ').*'/) { "#{$1}#{send(header_name)}'"}
end

# Adapted from WEBrick::Utils. Skips cert extensions so it
# can be used as a CA bundle
def create_self_signed_cert(bits, cn, comment)
  rsa = OpenSSL::PKey::RSA.new(bits)
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 1
  name = OpenSSL::X509::Name.new(cn)
  cert.subject = name
  cert.issuer = name
  cert.not_before = Time.now
  cert.not_after = Time.now + (365*24*60*60)
  cert.public_key = rsa.public_key
  cert.sign(rsa, OpenSSL::Digest::SHA1.new)
  return [cert, rsa]
end

## standard tasks

desc "Run all tests"
task :test do
  exec 'script/test'
end

desc "Generate certificates for SSL tests"
task :'test:generate_certs' do
  cert, key = create_self_signed_cert(1024, [['CN', 'localhost']], 'Faraday Test CA')
  FileUtils.mkdir_p 'tmp'
  File.open('tmp/faraday-cert.key', 'w') {|f| f.puts(key) }
  File.open('tmp/faraday-cert.crt', 'w') {|f| f.puts(cert.to_s) }
end

file 'tmp/faraday-cert.key' => :'test:generate_certs'
file 'tmp/faraday-cert.crt' => :'test:generate_certs'

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/#{name}.rb"
end
