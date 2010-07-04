__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'cgi'
require 'openssl'
require 'socket'
require 'uri'
require 'timeout'

require 'excon/connection'
require 'excon/errors'
require 'excon/response'
require 'excon/socket'

module Excon

  unless const_defined?(:VERSION)
    VERSION = '0.1.1'
  end

  def self.chunk_size
    @@chunk_size ||= 24576 #24KB
  end

  def self.chunk_size=(size)
    @@chunk_size = size
  end

  def self.new(url, params = {})
    Excon::Connection.new(url, params)
  end

  %w{connect delete get head options post put trace}.each do |method|
    eval <<-DEF
      def self.#{method}(url, params = {}, &block)
        new(url).request(params.merge!(:method => '#{method.upcase}'), &block)
      end
    DEF
  end

end
