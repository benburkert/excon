module Excon
  class Socket
    attr_accessor :host, :port

    CRLF = "\r\n"

    def initialize(host, port, options = {})
      @host, @port = host, port

      @chunk_size = options.fetch(:chunk_size, Excon.chunk_size)
      @buffer     = options.fetch(:buffer, StringIO.new)
    end

    def write(io)
      flush_stale_connections!

      until io.eof?
        socket << io.read(@chunk_size)
      end
    end

    def read(buffer = @buffer)
      loop do
        until buffer.pos == buffer.length
          yield buffer
        end

        pos = buffer.pos

        buffer << socket.readpartial(@chunk_size)

        buffer.rewind
        buffer.seek(pos)
      end
    end

    def read_status
      read do |buffer|
        return buffer.readline(CRLF)[9..11]
      end
    end

    def read_headers
      headers = {}

      read do |buffer|
        line = buffer.readline(CRLF).chomp(CRLF)

        return if line.empty?

        yield *line.split(': ')
      end
    end

    def read_fixed_body(total_length)
      length = 0
      read do |buffer|
        pos = buffer.pos

        yield buffer

        length += buffer.pos - pos

        return if length == total_length
      end
    end

    def read_chunked_body
      chunk, chunk_size = '', nil
      read do |buffer|
        chunk_size ||= buffer.readline(CRLF).chomp(CRLF).to_i(16)

        return if chunk_size == 0

        buffer.read(chunk_size, chunk)
        eoc = buffer.read(2)

        if eoc == CRLF
          yield StringIO.new(chunk)
          chunk, chunk_size = '', nil
        else
          chunk_size -= chunk.size
        end
      end
    end

    def flush_stale_connections!
      reset! if socket.closed?
    end

    def reset!
      @socket = nil
    end

    def socket
      @socket ||= TCPSocket.new(@host, @port)
    end

    def change(buffer)
      initial = buffer.size
      yield
      buffer.size - initial
    end
  end
end
