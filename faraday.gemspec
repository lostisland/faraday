# -*- encoding: utf-8 -*-
require File.expand_path('../lib/faraday/version', __FILE__)

Gem::Specification.new do |s|
  s.add_development_dependency('rake', ['~> 0.8.7'])
  s.add_development_dependency('sinatra', ['~> 1.0.0'])
  s.add_runtime_dependency('addressable', ['~> 2.1.1'])
  s.add_runtime_dependency('multipart-post', ['~> 1.0.1'])
  s.add_runtime_dependency('rack', ['~> 1.0.1'])
  s.name = 'faraday'
  s.version = Faraday::VERSION
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if s.respond_to? :required_rubygems_version=
  s.authors = ["rick"]
  s.summary = %q{HTTP/REST API client library}
  s.description = %q{HTTP/REST API client library with pluggable components}
  s.email = ['technoweenie@gmail.com']
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = "http://github.com/technoweenie/faraday"
  s.extra_rdoc_files = ['LICENSE', 'README.rdoc']
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
end
