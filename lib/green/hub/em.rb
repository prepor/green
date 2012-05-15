require 'eventmachine'

class ::EM::Timer
  include Green::Waiter

  def green_cancel
    cancel
  end
end

module ::EM::Deferrable
  include Green::Waiter

  def green_cancel
    # instance_variable_get(:@callbacks).each { |c| cancel_callback c }
    # instance_variable_get(:@errbacks).each { |c| cancel_errback c }
    # cancel_timeout
  end
end

class Green
  class Hub
    class EM < Hub
      class SocketWaiter < Green::SocketWaiter
        class Handler < ::EM::Connection
          attr_accessor :waiter
          def notify_readable        
            check_readers
          end

          def check_readers
            if notify_readable? && waiter.readers.size > 0
              Green.hub.callback { check_readers }
              waiter.readers.pop.switch
            else
              self.notify_readable = false
            end
          end

          def notify_writable
            check_writers
          end

          def check_writers
            if notify_writable? && waiter.writers.size > 0
              Green.hub.callback { check_writers }
              waiter.writers.pop.switch
            else
              self.notify_writable = false
            end
          end
        end

        def wait_read
          @handler ||= make_handler
          @handler.notify_readable = true
          super
        end

        def wait_write
          @handler ||= make_handler
          @handler.notify_writable = true
          super
        end

        def make_handler
          ::EM.watch socket, Handler do |c|
            c.waiter = self
          end
        end

        def cancel
          return unless @handler
          sig = @handler.signature
          ::EM.detach_fd sig
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

      def callback(&blk)
        ::EM.next_tick(&blk)
      end

      def socket_waiter(socket)
        SocketWaiter.new socket
      end
    end
  end
end