require "fcntl"
require 'socket'
require 'kgio'

class Green
  
  ERRORS = Errno::constants.each_with_object({}) do |c, h|
    const = Errno.const_get(c)
    h[const::Errno] = const    
  end

  # TODO puts
  class Socket < ::Socket
    READ_BUFFER_SIZE = 65536

    include Kgio::SocketMethods

    def write(str)
      kgio_write(str)
      str.bytesize
    end

    def read(length = nil, buffer = nil)
      res = []
      readed = 0
      begin # begin ... while
        need_read = if length
          length - readed
        else
          READ_BUFFER_SIZE
        end        
        data = kgio_read(need_read)
        if data.nil? && length.nil? && readed == 0
          return ''
        elsif data.nil? && readed == 0
          return nil
        elsif data.nil?
          return buffer ? buffer.replace(res * '') : res * ''
        else
          readed += data.size
          res << data
        end
      end while length != readed
      return buffer ? buffer.replace(res * '') : res * ''
    end

    def recv(maxlen, flags = 0)
      recv_nonblock(maxlen)
    rescue Errno::EAGAIN
      waiter.wait_read
      retry
    end

    def send(mesg, flags, dest_sockaddr = nil)
      # FIXME
      write mesg
    end

    def kgio_wait_readable
      waiter.wait_write
    end

    def kgio_wait_readable
      waiter.wait_read
    end

    def self.accept_socket_class
      self
    end

    def accept
      s, a = accept_nonblock
      [self.class.accept_socket_class.for_fd(s.fileno), a]
    rescue Errno::EAGAIN
      waiter.wait_read
      retry
    end

    def connect(sock_addr)
      connect_nonblock(sock_addr)
    rescue Errno::EINPROGRESS
      error, = getsockopt(::Socket::SOL_SOCKET, ::Socket::SO_ERROR).unpack('i')
      if error != 0
        raise ERRORS[error]
      else
        waiter.wait_write
      end
    end

    def waiter
      @waiter ||= Green.hub.socket_waiter(self)
    end
  end

  class TCPSocket < Socket
    def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
      addrinfo = Addrinfo.tcp(remote_host, remote_port)
      super(addrinfo.ipv4? ? :INET : :INET6, :STREAM, 0)
      if local_host && local_port
        bind(Addrinfo.tcp(local_host, local_port))
      end
      connect addrinfo
    end
  end

  class TCPServer < Socket
    def initialize(host, port)
      addrinfo = Addrinfo.tcp(host, port)
      super(addrinfo.ipv4? ? :INET : :INET6, :STREAM, 0)
      setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
      bind(addrinfo)
      listen(5)
    end


    def self.accept_socket_class
      TCPSocket
    end

    def accept
      super[0]
    end
  end
end
