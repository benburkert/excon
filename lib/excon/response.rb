module Excon
  class Response

    def self.parse(socket, params = {}, &block)
      if params[:block]
        print "  \e[33m[WARN] params[:block] is deprecated, please pass the block to the request\e[0m"
        block = params[:block]
      end

      response = new

      response.status = socket.read_status.to_i

      socket.read_headers do |key, value|
        response.headers[key] = value
      end

      unless params[:method] == 'HEAD'
        if !block || (params[:expects] && ![*params[:expects]].include?(response.status))
          response.body = ''
          block = lambda { |chunk| response.body << chunk }
        end

        if response.headers['Content-Length']
          return response if response.headers['Content-Length'].to_i == 0
          socket.read_fixed_body(response.headers['Content-Length'].to_i, &block)
        elsif response.headers['Transfer-Encoding'] == 'chunked'
          socket.read_chunked_body(&block)
        else
          socket.read_body(&block)
        end
      end

      response
    #ensure
      #if response && response.headers['Connection'] == 'close'
        #socket.reset! if socket
      #end
    end

    attr_accessor :body, :headers, :status

    def initialize(attributes = {})
      @body    = attributes[:body] || ''
      @headers = attributes[:headers] || {}
      @status  = attributes[:status]
    end

  end
end
