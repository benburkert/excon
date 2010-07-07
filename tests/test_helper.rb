$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/excon'))

require 'fileutils'
require 'open-uri'
require 'shindo'
require 'realweb'


def with_rackup(configru = local_file('config.ru'))
  RealWeb.with_server(configru) do |server|
    yield "http://#{server.host}:#{server.port}"
  end
end

def with_random_server
  with_rackup(local_file('fixtures', 'random.ru')) do |base_url|
    checksum = open(base_url + '/checksum').read
    yield base_url, checksum
  end
end

def local_file(*parts)
  File.expand_path(File.join(File.dirname(__FILE__), *parts))
end

def md5(data)
  Digest::MD5.hexdigest(data)
end
