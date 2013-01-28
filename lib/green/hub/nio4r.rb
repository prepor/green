class Green
  class Hub
    class Nio4r < Hub
      class SocketWaiter < Green::SocketWaiter
        attr_reader :reactor
        def initialize(reactor, socket)
          super socket
          @reactor = reactor
        end

        def wait_read
          make_monitor :r
        end

        def wait_write
          make_monitor :w
        end

        def make_monitor(interest)
          m = reactor.selector.register(socket, interest)
          g = Green.current
          m.value = proc { g.switch }
          Green.hub.switch
        ensure
          reactor.selector.deregister socket
        end
      end

      class Timer
        attr_reader :reactor, :fire_at, :clb
        def initialize(reactor, fire_at, &clb)
          @reactor, @fire_at, @clb = reactor, fire_at, clb
        end

        def run
          @runned = true
          clb.call
        end

        def green_cancel
          return if @canceled || @runned
          @canceled = true
          reactor.cancel_timer self
        end

        def <=>(v)
          @fire_at <=> v.fire_at
        end
      end

      MIN_TIMEOUT = 0.0001
      MAX_TIMEOUT = 0.01

      attr_reader :callbacks, :timers, :cancel_timers
      def initialize(*args)
        require 'nio'
        require 'algorithms'

        @callbacks = []
        @timers = Containers::MinHeap.new
        @cancel_timers = {}
        super
      end

      def reactor_running?
        @reactor_running
      end

      def run
        @reactor_running = true
        @selector = NIO::Selector.new
        while @reactor_running
          run_callbacks
          run_timers
          @selector.select(time_till_first_event) do |m|
            m.value.call
          end
        end
      end

      def run_timers
        now = Time.now
        while (t = @timers.next)
          if t.fire_at <= now
            @timers.pop
            if @cancel_timers[t]
              @cancel_timers.delete t
            else
              t.run
            end
          else
            break
          end
        end
      end

      def run_callbacks
        jobs, @callbacks = @callbacks, []
        begin
          i = 0
          while i < jobs.size
            job = jobs[i]
            jobs[i] = nil
            job.call
            i += 1
          end
        ensure
          @callbacks[0...0] = jobs[i..-1]  if i < jobs.size
        end
      end

      def time_till_first_event
        if @callbacks.size > 0
          MIN_TIMEOUT
        elsif @timers.size > 0
          @timers.next.fire_at - Time.now + MIN_TIMEOUT
        else
          MAX_TIMEOUT
        end
      end

      def selector
        @selector
      end

      def cancel_timer(timer)
        @cancel_timers[timer] = true
      end

      def timer(n, &blk)
        @timers << Timer.new(self, Time.now + n, &blk)
      end

      def callback(cb=nil, &blk)
        @callbacks << (cb || blk)
      end

      def socket_waiter(socket)
        SocketWaiter.new self, socket
      end

      def stop
        @reactor_running = false
      end
    end
  end
end
