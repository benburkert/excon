module Excon
  class Request
    attr_accessor :method, :path, :headers, :body

    def initialize(method, path, headers, body)
      @method   = method.upcase
      @path     = path
      @headers  = headers
      @body     = body
    end

    def perform(socket)
      if bodyless?
        socket.write(message_header)
      else
        socket.write(message_header, message_body)
      end
    end

    def bodyless?
      %w[ OPTIONS GET HEAD DELETE TRACE ].include?(method) || body.nil?
    end

    def message_header
      [ request_line, header_fields, CRLF].join(CRLF)
    end

    def request_line
      "#{method.upcase} #{path} HTTP/1.1"
    end

    def header_fields
      request_headers.map {|(k,v)| [ k, v].join(': ') }.join(CRLF)
    end

    def request_headers
      general_headers.merge(entity_headers).merge(headers)
    end

    def general_headers() {} end

    def entity_headers
      h = {}

      return h if bodyless?

      if body.respond_to? :length
        h['Content-Length'] = body.size
      end

      h
    end

    alias message_body body
  end
end
