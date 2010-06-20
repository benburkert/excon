module Excon
  class Socket
    attr_accessor :host, :port

    CRLF = "\r\n"

    def initialize(host, port, options = {})
      @host, @port = host, port

      @chunk_size = options.fetch(:chunk_size, Excon.chunk_size)
      @buffer     = options.fetch(:buffer, '')
    end

    def write(io)
      reset_stale!

      until io.eof?
        socket << io.read(@chunk_size)
      end
    end

    def drain
      while buf = socket.readpartial(@chunk_size)
        yield buf if block_given?
      end

    rescue EOFError
      nil
    end

    def read
      drain do |data|
        @buffer << data
        yield
      end
    end

    def read_status
      read do
        if @buffer.include?(CRLF)
          status_line, @buffer = @buffer.split(CRLF, 2)
          return status_line[9..11]
        end
      end
    end

    def read_headers
      headers = {}

      read do
        if @buffer.include?(CRLF * 2)
          headers, @buffer = @buffer.split(CRLF * 2, 2)

          headers.split(CRLF).each do |line|
            yield *line.split(': ')
          end

          return
        else
          if @buffer[-2..-1] == CRLF
            lines = @buffer.split(CRLF)
            @buffer = ''
          else
            lines = @buffer.split(CRLF)
            @buffer = lines.pop
          end

          lines.each do |line|
            yield *line.split(': ')
          end
        end
      end
    end

    def read_fixed_body(total_length)
      length = 0

      read do
        length += @buffer.size

        yield @buffer

        @buffer = ''

        return if length == total_length
      end
    end

    def read_chunked_body
      chunk_buffer, chunk_size = '', nil

      read do
        if chunk_size.nil?
          if @buffer.include?(CRLF)
            chunk_line, @buffer = @buffer.split(CRLF, 2)
            chunk_size = chunk_line.chomp(CRLF).to_i(16)

            return if chunk_size == 0
          else
            break
          end
        end

        if @buffer.size >= chunk_size + 2
          # we can read a whole chunk + CRLF
          yield @buffer.slice!(0, chunk_size + 2).chomp(CRLF)
          chunk_size = nil
          redo
        else
          # read part of a chunk, update chunk_size, break to read again
          chunk_size -= @buffer.size
          yield @buffer
          @buffer = ''
        end
      end
    end

    def reset_stale!
      reset! if socket.closed?
    end

    def reset!
      @socket.close if socket.open? unless socket.nil?
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
