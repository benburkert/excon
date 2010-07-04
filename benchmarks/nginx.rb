$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'lib/excon')

require 'benchmark'
require 'net/http'
require 'open-uri'

COUNT = 100
SIZES = %w( 1MB 10MB )

puts "Nginx Benchmarks"
puts

Benchmark.bmbm(25) do |bench|
  SIZES.each do |size|
    bench.report("excon - #{size}") do
      COUNT.times do
        Excon.new('http://127.0.0.1', :port => 8080).request(:method => 'GET', :path => "/#{size}")
      end
    end
    bench.report("excon (persistent) - #{size}") do
      excon = Excon.new('http://127.0.0.1', :port => '8080')
      COUNT.times do
        excon.request(:method => 'GET', :path => "/#{size}")
      end
    end
    bench.report("net/http - #{size}") do
      COUNT.times do
        Net::HTTP.start('127.0.0.1', 8080) {|http| http.get("/#{size}") }
      end
    end
    bench.report("net/http (persistent) - #{size}") do
      Net::HTTP.start('127.0.0.1', 8080) do |http|
        COUNT.times do
          http.get("/#{size}")
        end
      end
    end
    bench.report("open-uri - #{size}") do
      COUNT.times do
        open("http://127.0.0.1:8080/#{size}").read
      end
    end
  end
end
