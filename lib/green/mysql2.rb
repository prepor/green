require 'mysql2'
class Green
  module Mysql2
    class Client < ::Mysql2::Client
      def query(sql, opts={})
        super(sql, opts.merge(:async => true))
        green_waiter.wait_read
        async_result
      end

      def green_waiter
        @green_waiter ||= Green.hub.socket_waiter(Socket.for_fd(self.socket))
      end
    end
  end
end