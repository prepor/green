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
    end
  end
end