module Excon
  class Response

    def self.parse(socket, params = {}, &block)
      if params[:block]
        print "  \e[33m[WARN] params[:block] is deprecated, please pass the block to the request\e[0m"
        block = params[:block]
      end

      response = if block
          new(params[:method], block)
        else
          new(params[:method])
        end

      response.parse(socket)

      response
    end

    attr_accessor :body, :headers, :status, :callback, :request_method

    def initialize(request_method, callback = method(:add_body_chunk))
      @request_method, @callback = request_method.upcase, callback
      @body, @headers = '', {}
    end

    def parse(socket)
      self.status = socket.read_status.to_i

      socket.read_headers do |key, value|
        self.headers[key] = value
      end

      read_body_from(socket) unless bodyless?
    end

    def read_body_from(socket)
      if fixed_body?
        socket.read_fixed_body(content_length, &callback)
      elsif chunked_body?
        socket.read_chunked_body(&callback)
      else
        socket.read_body(&callback)
      end
    end

    def fixed_body?
      headers.keys.include?('Content-Length')
    end

    def chunked_body?
      headers.keys.include?('Transfer-Encoding')
    end

    def content_length
      headers['Content-Length'].to_i
    end

    def add_body_chunk(chunk)
      body << chunk
    end

    def bodyless?
      request_method == 'HEAD' ||
        (fixed_body? && content_length == 0)
    end

    def close_connection?
      headers['Connection'] == 'close'
    end
  end
end
