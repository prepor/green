# -*- coding: utf-8 -*-
require 'eventmachine'

class ::EM::Timer
  def green_cancel
    cancel
  end
end

module ::EM::Deferrable
  def green_cancel
    instance_variable_get(:@callbacks).each { |c| cancel_callback c }
    instance_variable_get(:@errbacks).each { |c| cancel_errback c }
    cancel_timeout
  end
end

class Green
  class Hub
    class EM < Hub
      class SocketWaiter < Green::SocketWaiter
        class Handler < ::EM::Connection
          attr_accessor :green
          def notify_readable
            green.switch
          end

          def notify_writable
            green.switch
          end
        end

        def wait_read
          make_handler(:readable)
        end

        def wait_write
          make_handler(:writable)
        end

        def make_handler(mode)
          h = ::EM.watch socket, Handler do |c|
            c.green = Green.current
          end
          case mode
          when :readable
            h.notify_readable = true
          when :writable
            h.notify_writable = true
          end
          Green.hub.switch
        ensure
          h.detach
        end

      end
      # если мы запускаем приложение внутри thin или rainbows с EM, то значит мы уже внутри EM-реактора, а hub должен переключиться в main тред.
      def run
        if ::EM.reactor_running?
          loop do
            Green.main.switch
          end
        else
          ::EM.run
        end
      end

      def timer(n, &blk)
        ::EM::Timer.new(n, &blk)
      end

      def callback(cb=nil, &blk)
        ::EM.next_tick(cb || blk)
      end

      def socket_waiter(socket)
        SocketWaiter.new socket
      end

      def stop
        EM.stop
      end
    end
  end
end
