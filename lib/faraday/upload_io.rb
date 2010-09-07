begin
  require 'composite_io'
  require 'parts'
  require 'stringio'
rescue LoadError
  puts "Install the multipart-post gem."
  raise
end

module Faraday
  CompositeReadIO = ::CompositeReadIO
  UploadIO        = ::UploadIO
  Parts           = ::Parts
end