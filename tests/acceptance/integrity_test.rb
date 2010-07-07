require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

with_random_server do |base_url, checksum|
  Shindo.tests do
    test('Content-Length delimited response preserves body data') do
      connection = Excon.new(base_url)

      response = connection.request(:method => 'GET', :path => '/content-length')

      md5(response.body) == checksum
    end

    test('Chunked encoding response preserves body data') do
      connection = Excon.new(base_url)

      response = connection.request(:method => 'GET', :path => '/chunked')

      md5(response.body) == checksum
    end

    test('EOF delimited response preserves body data') do
      connection = Excon.new(base_url)

      response = connection.request(:method => 'GET', :path => '/EOF')

      md5(response.body) == checksum
    end
  end
end
