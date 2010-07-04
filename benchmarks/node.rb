$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'lib/excon')

require 'benchmark'
require 'net/http'
require 'open-uri'

COUNT = 100
PORT_MAP = {
  '1MB'           => 8081,
  '1MB Chunked'   => 8082,
  '10MB'          => 8083,
  '10MB Chunked'  => 8084
}

puts "Node Benchmarks"
puts

Benchmark.bmbm(25) do |bench|
  PORT_MAP.each do |size, port|
    bench.report("excon - #{size}") do
      COUNT.times do
        Excon.new('http://127.0.0.1', :port => port).request(:method => 'GET', :path => "/")
      end
    end
    bench.report("excon (persistent) - #{size}") do
      excon = Excon.new('http://127.0.0.1', :port => port)
      COUNT.times do
        excon.request(:method => 'GET', :path => "/")
      end
    end
    bench.report("net/http - #{size}") do
      COUNT.times do
        Net::HTTP.start('127.0.0.1', port) {|http| http.get("/") }
      end
    end
    bench.report("net/http (persistent) - #{size}") do
      Net::HTTP.start('127.0.0.1', port) do |http|
        COUNT.times do
          http.get("/")
        end
      end
    end
    bench.report("open-uri - #{size}") do
      COUNT.times do
        open("http://127.0.0.1:#{port}/").read
      end
    end
  end
end
