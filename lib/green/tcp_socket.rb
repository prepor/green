class Green
  class Socket < ::Socket
    def accept
      accept_nonblock
    end

    def connect(sock_addr)
      connect_nonblock(sock_addr)
    end

    def send(mesg, flags = 0, dest_sockaddr = nil)
      super(mesg, flags, dest_sockaddr)
    rescue Errno::EAGAIN => e
      wait_write
      retry
    end

    def recv(maxlen, flags = 0)
      super(maxlen, flags = 0)
    rescue Errno::EAGAIN => e
      wait_read
      retry
    end
  end
end