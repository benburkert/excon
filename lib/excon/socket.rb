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
      yield unless @buffer.empty?

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

    def read_body
      read do
        yield @buffer

        ending, @buffer = @buffer[-2..-1], ''

        return if ending == CRLF
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
      size = nil

      read do
        state, chunk_buffer = :ready, ''

        begin
          size, state = read_chunk_header if size.nil?

          if state == :ready
            chunk, size, state = read_chunk(size)
            chunk_buffer << chunk
          end

        end while state == :ready

        yield chunk_buffer unless chunk_buffer.empty?

        return if state == :EOF
      end
    end

    def read_chunk_header
      if index = @buffer.index(CRLF)
        size = @buffer.slice!(0, index + 2).chomp!.to_i(16)
      end

      state = if size.nil? || @buffer.empty?
          :not_ready
        elsif size == 0
          :EOF
        else
          :ready
        end

      return size, state
    end

    def read_chunk(size)

      if @buffer.size >= size + 2
        return @buffer.slice!(0, size + 2).chomp!(CRLF), nil, :ready
      else
        data, @buffer = @buffer, ''
        return data, size - data.size, :empty
      end
    end

    def reset_stale!
      reset! if socket.closed?
    end

    def reset!
      @socket.close unless @socket.closed? unless @socket.nil?
      @socket = nil
    end

    def socket
      @socket ||= TCPSocket.new(@host, @port)
    end
  end
end
