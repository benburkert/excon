$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'perftools'
require 'net/http'
require 'open-uri'
require 'fog'

CONFIG = YAML.load_file("#{ENV['HOME']}/.fog")[:excon]
s3 = Fog::AWS::S3.new(CONFIG)

dir = s3.directories.create(:key => 'excon-benchmarks')

SIZES = [1, 10, 100]

SIZES.each do |size|
  unless dir.files.head("#{size}MB")
    File.open('/dev/random', 'r') do |f|
      dir.files.create(:key => "#{size}MB", :body => f.read(1024 * 1024 * size))
    end
  end
end

COUNT = 1

puts "S3 Perf"
puts

SIZES.each do |size|
  PerfTools::CpuProfiler.start("./tmp/s3_#{size}MB") do
    COUNT.times do
      Fog::AWS::S3.new(CONFIG).directories.get('excon-benchmarks').files.get("#{size}MB")
    end
  end
end
