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
      request = Request.new(params[:method], path_for(params), headers_for(params), body_for(params))

      request.perform(socket)

      response = Response.parse(socket, params, &block)
    ensure
      reset if response.close_connection? unless response.nil?
    end

    def path_for(params)
      path = params[:path] || @connection[:path] || raise(ArgumentException, ":path parameter missing.")
      path = "/#{path}" unless path[0] == ?/

      unless (query_params = params[:query] || @connection[:query] || {}).empty?
        [ path, query_for(query_params) ].join('?')
      else
        path
      end
    end

    def query_for(query_params)
      query_params.map {|(k,v)| query_part(k,v) }.join('&')
    end

    def query_part(key, value)
      value.nil? ? escape(key) : [ escape(key), escape(value) ].join('=')
    end

    def headers_for(params)
      headers = params[:headers] || @connection[:headers]

      headers['Host'] ||= params[:host] || @connection[:host]

      headers
    end

    def body_for(params)
      params[:body] || @connection[:body]
    end

    def reset
      @socket.close! unless @socket.nil?
      @socket = nil
    end

    private

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
