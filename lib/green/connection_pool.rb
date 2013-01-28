class Green
  class ConnectionPool
    class Proxy < BasicObject
      def initialize(pool)
        @pool = pool
      end

      def method_missing(method, *args, &blk)
        @pool.execute do |conn|
          conn.__send__(method, *args, &blk)
        end
      end
    end

    attr_accessor :available, :pending, :disconnect_class, :new_block

    def initialize(opts = {}, &block)
      @available = []   # pool of free connections
      @pending   = []   # pending reservations (FIFO)

      @disconnect_class = opts[:disconnect_class]
      @new_block = block
      opts[:size].times do
        @available.push(@new_block.call)
      end
    end

    def execute
      begin
        conn = acquire
        yield conn
      rescue => e
        if @disconnect_class && e.is_a?(@disconnect_class)
          disconnected = true
          @available << @new_block.call
        else
          raise
        end
      ensure
        if disconnected
          try_next
        else
          release conn
          try_next
        end
      end
    end

    def proxy
      @proxy ||= Proxy.new(self)
    end

    def acquire
      g = Green.current
      if conn = @available.pop
        conn
      else
        @pending.push g
        Green.hub.wait { @pending.delete g }
        acquire
      end
    end

    def release(conn)
      @available.push conn
    end

    def try_next
      if pending = @pending.shift
        Green.hub.callback { pending.switch }
      end
    end
  end
end
