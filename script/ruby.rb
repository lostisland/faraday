# Opinionated module that picks out a ruby library's name and version based on
# some conventions:
#
# * #{lib_name}.gemspec
# * A VERSION constant defined in lib/#{lib_name}.rb
#
# Example:
#
#   # foo.gemspec
#   # lib/foo.rb
#   module Foo
#     VERSION = "0.1"
#   end

module MakeScript
  extend self

  def lib_name
    @lib_name ||= Dir['*.gemspec'].first.split('.').first
  end

  def version
    @version ||= begin
      line = File.read("lib/#{lib_name}.rb")[/^\s*VERSION\s*=\s*.*/]
      line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
    end
  end

  def gemspec_file
    @gemspec_file ||= "#{lib_name}.gemspec"
  end

  def gem_file
    @gem_file ||= "#{lib_name}-#{version}.gem"
  end
end
