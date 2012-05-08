require 'eventmachine'
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