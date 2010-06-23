require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/excon'))

require 'shindo'
require 'realweb'

def local_file(*parts)
  File.expand_path(File.join(File.dirname(__FILE__), *parts))
end

def running?(pid)
  Process.kill(0, pid)
  data = `lsof -p #{pid} -nP -i | grep ruby | grep TCP`.chomp
  puts data.inspect
  !data.empty?
end

def with_rackup(configru = local_file('config.ru'))
  RealWeb.with_server(configru) do |server|
    yield "http://#{server.host}:#{server.port}"
  end
end
