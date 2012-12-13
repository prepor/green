require 'green'
require 'ffi-rzmq'

class Green
  module ZMQ
    class Waiter
      attr_reader :socket_waiter, :waiters
      def initialize(fd)
        @socket_waiter = Green.hub.socket_waiter(Socket.for_fd(fd))
        @waiters = []
        @notifier = Green.spawn do
          while true
            @socket_waiter.wait_read
            wake
          end
        end
      end

      def lock
        g = Green.current
        @waiters << g
        Green.hub.wait { @waiters.delete g }
      end

      def wake
        w = @waiters.shift
        Green.hub.callback { w.switch } if w
      end

      def cancel
        @notifier.kill
      end
    end
  end
end

module ZMQ
  class Context
    alias :original_terminate :terminate
    def terminate
      Green.hub.callback do
        original_terminate
      end
    end
  end

  class Socket
    def initialize(*args)
      super
      fd, = [].tap { |a| getsockopt(ZMQ::FD, a) }
      @waiter = Green::ZMQ::Waiter.new fd
    end

    alias :bsendmsg :sendmsg
    def sendmsg(message, flags = 0)
      return bsendmsg(message, flags) if (flags & ZMQ::NonBlocking) != 0
      flags |= ZMQ::NonBlocking
      loop do
        rc = bsendmsg message, flags
        if rc == -1 && ZMQ::Util.errno == EAGAIN
          @waiter.lock
        else
          @waiter.wake
          return rc
        end
      end
    end

    alias :brecvmsg :recvmsg
    def recvmsg(message, flags = 0)
      return brecvmsg(message, flags) if (flags & ZMQ::NonBlocking) != 0
      flags |= ZMQ::NonBlocking
      loop do
        rc = brecvmsg message, flags
        if rc == -1 && ZMQ::Util.errno == EAGAIN
          @waiter.lock
        else
          @waiter.wake
          return rc
        end
      end
    end

    alias :original_close :close
    def close
      @waiter.cancel
      Green.hub.callback do
        original_close
      end
    end
  end
end
