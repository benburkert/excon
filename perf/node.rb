$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'lib/excon')

require 'perftools'
require 'net/http'
require 'open-uri'

COUNT = 100
PORT_MAP = {
  '1MB'           => 8081,
  '1MB_chunked'   => 8082,
  '10MB'          => 8083,
  '10MB_chunked'  => 8084
}

puts "Node Perf"
puts

PORT_MAP.each do |size, port|
  PerfTools::CpuProfiler.start("./tmp/node_#{size}") do
    COUNT.times do
      Excon.new('http://127.0.0.1', :port => port).request(:method => 'GET', :path => "/")
    end
  end
  PerfTools::CpuProfiler.start("./tmp/node_persistent_#{size}") do
    excon = Excon.new('http://127.0.0.1', :port => port)
    COUNT.times do
      excon.request(:method => 'GET', :path => "/")
    end
  end
end
