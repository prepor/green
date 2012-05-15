require "fcntl"

class Green
  class Socket < ::Socket
    READ_BUFFER_SIZE = 65536

    def self.accept_socket_class
      self
    end

    def set_nonblock
      flags = fcntl(Fcntl::F_GETFL, 0)
      fcntl(Fcntl::F_SETFL, flags | Fcntl::O_NONBLOCK)
    end

    def accept
      s, a = accept_nonblock
      [self.class.for_fd(s.fileno), a]
    rescue Errno::EAGAIN
      waiter.wait_read
      retry
    end

    def connect(sock_addr)
      connect_nonblock(sock_addr)
    rescue Errno::EINPROGRESS
      waiter.wait_write
    end

    def send(mesg, flags = 0, dest_sockaddr = nil)
      super(mesg, flags, dest_sockaddr)
    rescue Errno::EAGAIN
      waiter.wait_write
      retry
    end

    def recv(maxlen, flags = 0)
      super(maxlen, flags = 0)
    rescue Errno::EAGAIN
      waiter.wait_read
      retry
    end

    def write(string)
      green_write string
    end

    def green_write(string, original_size = string.size)
      writed = write_nonblock(string)
      if writed == string.size
        return original_size
      else
        green_write(string[writed, string.size])
      end
    rescue Errno::EAGAIN
      waiter.wait_write
      retry
    end

    def read(length = nil, buffer = nil)      
      green_read length, buffer || ""
    end

    def green_read(length, buffer = "")
      while length != buffer.size
        need_read = if length
          length - buffer.size
        else
          READ_BUFFER_SIZE
        end
        begin          
          buffer << read_nonblock(need_read)
        rescue EOFError, Errno::ECONNRESET
          return buffer
        rescue Errno::EAGAIN
          waiter.wait_read
        end
      end
      buffer
    end

    def waiter
      @waiter ||= Green.hub.socket_waiter(self)
    end

    def close
      waiter.cancel
      super      
    end
  end

  class TCPSocket < Socket
    def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
      super(:INET, :STREAM, 0)
      if local_host && local_port
        bind(Addrinfo.tcp(local_host, local_port))
      end
      connect Addrinfo.tcp(remote_host, remote_port)
    end
  end

  class TCPServer < Socket
    def initialize(host, port)
      super(:INET, :STREAM, 0)
      setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
      bind(Addrinfo.tcp(host, port))
    end


    def self.accept_socket_class
      TCPSocket
    end

    def accept
      super[0]
    end
  end
end