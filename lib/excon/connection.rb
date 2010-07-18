module Excon
  class Connection

    def initialize(url, params = {})
      uri = URI.parse(url)
      @connection = {
        :headers  => {},
        :host     => uri.host,
        :path     => uri.path,
        :port     => uri.port,
        :query    => uri.query,
        :scheme   => uri.scheme
      }.merge!(params)
    end

    def request(params, &block)
      begin
        params[:path] ||= @connection[:path]
        unless params[:path][0..0] == '/'
          params[:path] = "/#{params[:path]}"
        end
        request = "#{params[:method]} #{params[:path]}?"
        for key, value in (params[:query] || @connection[:query] || {})
          request << "#{key}#{value && "=#{CGI.escape(value.to_s)}"}&"
        end
        request.chop!
        request << " HTTP/1.1\r\n"
        params[:headers] ||= @connection[:headers]
        params[:headers]['Host'] ||= params[:host] || @connection[:host]
        unless params[:headers]['Content-Length']
          params[:headers]['Content-Length'] = (params[:body] && params[:body].length) || 0
        end
        for key, value in params[:headers]
          request << "#{key}: #{value}\r\n"
        end
        request << "\r\n"

        io = if body = (params[:body] || @connection[:body])
          if body.is_a?(String)
            StringIO.new(request + body)
          else
            raise 'fail'
          end
        else
          StringIO.new(request)
        end


        socket.write(io)

        response = Excon::Response.parse(socket, params, &block)
        if response.headers['Connection'] == 'close'
          reset
        end
        response
      rescue => socket_error
        reset
        raise(socket_error)
      end

      if params[:expects] && ![*params[:expects]].include?(response.status)
        reset
        raise(Excon::Errors.status_error(params, response))
      else
        response
      end

    rescue => request_error
      if params[:idempotent] &&
          (!request_error.is_a?(Excon::Errors::Error) || response.status != 404)
        retries_remaining ||= 4
        retries_remaining -= 1
        if retries_remaining > 0
          retry
        else
          raise(request_error)
        end
      else
        raise(request_error)
      end
    end

    def reset
      @socket = nil
    end

    private

    def connect
      new_socket = nil
      Timeout::timeout(1) do
        new_socket = TCPSocket.open(@connection[:host], @connection[:port])

        if @connection[:scheme] == 'https'
          @ssl_context = OpenSSL::SSL::SSLContext.new
          @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          new_socket = OpenSSL::SSL::SSLSocket.new(new_socket, @ssl_context)
          new_socket.sync_close = true
          new_socket.connect
        end

        new_socket
      end
    rescue Timeout::Exception
      new_socket.close unless new_socket.nil?
      retry
    end

    def closed?
      sockets[socket_key] && sockets[socket_key].closed?
    end

    def socket
      @socket ||= begin
        if @connection[:scheme] == 'https'
          SSLSocket.new(@connection[:host], @connection[:port])
        else
          Socket.new(@connection[:host], @connection[:port])
        end
      end
    end

    def sockets
      Thread.current[:_excon_sockets] ||= {}
    end

    def socket_key
      "#{@connection[:host]}:#{@connection[:port]}"
    end
  end
end
