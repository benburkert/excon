require 'digest/md5'
require 'stringio'

io = StringIO.new

::File.open('/dev/random', 'r') do |f|
  io << f.read(1024 * 1024 * 10) # 10MB
end

io.rewind

checksum = Digest::MD5.hexdigest(io.string)

class BodyStream
  def initialize(io)
    @io = io
    io.rewind
  end

  def each
    loop do
      data = @io.read(rand(1024 * 1024)) #0-1MB chunks
      return if data.nil?
      yield data
    end
  end
end

map '/checksum' do
  run lambda { [200, {}, checksum] }
end

map '/content-length' do
  run lambda { [200, {'Content-length' => io.string.size.to_s}, BodyStream.new(io)] }
end

map '/chunked' do
  use Rack::Chunked
  run lambda { [200, {}, BodyStream.new(io)] }
end

map '/EOF' do
  run lambda { [200, {}, BodyStream.new(io)] }
end
