module Excon
  class Response

    def self.parse(socket, params = {}, &block)
      if params[:block]
        print "  \e[33m[WARN] params[:block] is deprecated, please pass the block to the request\e[0m"
        block = params[:block]
      end

      response = new

      response.status = socket.read_status
      socket.read_headers do |key, value|
        response.headers[key] = value
      end

      unless params[:method] == 'HEAD'
        if !block || (params[:expects] && ![*params[:expects]].include?(response.status))
          response.body = ''
          block = lambda { |chunk| response.body << chunk }
        end

        if response.headers['Connection'] == 'close'
          block.call(socket.read)
        elsif response.headers['Content-Length']
          socket.read_fixed_body(response.headers['Content-Length'].to_i) do |buffer|
            response.body << buffer.read
          end

          remaining = response.headers['Content-Length'].to_i
          while remaining > 0
            block.call(socket.read([CHUNK_SIZE, remaining].min))
            remaining -= CHUNK_SIZE
          end
        elsif response.headers['Transfer-Encoding'] == 'chunked'
          socket.read_chunked_body do |buffer|
            response.body << buffer.read
          end
        end
      end

      response
    end

    attr_accessor :body, :headers, :status

    def initialize(attributes = {})
      @body    = attributes[:body] || ''
      @headers = attributes[:headers] || {}
      @status  = attributes[:status]
    end

  end
end
