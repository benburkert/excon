module Excon
  class SSLSocket < Socket

    def socket
      @ssl_socket ||= begin
        ssl_socket = OpenSSL::SSL::SSLSocket.new(super, ssl_context)
        ssl_socket.sync_close = true
        ssl_socket.connect
        ssl_socket
      end
    end

    def ssl_context
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ssl_context
    end

    def reset!
      super
      @ssl_socket.close unless @ssl_socket.closed? unless @ssl_socket.nil?
      @ssl_socket = nil
    end
  end
end
