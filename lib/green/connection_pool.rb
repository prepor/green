class Green
  class ConnectionPool
    undef :send

    def initialize(opts, &block)
      @reserved  = {}   # map of in-progress connections
      @available = []   # pool of free connections
      @pending   = []   # pending reservations (FIFO)

      opts[:size].times do
        @available.push(block.call) if block_given?
      end
    end

    # Choose first available connection and pass it to the supplied
    # block. This will block indefinitely until there is an available
    # connection to service the request.
    def execute
      g = Green.current
      begin
        conn = acquire(g)
        yield conn
      ensure
        release(g)
      end
    end

    private

      # Acquire a lock on a connection and assign it to executing fiber
      # - if connection is available, pass it back to the calling block
      # - if pool is full, yield the current fiber until connection is available
      def acquire(green)
        if conn = @available.pop
          @reserved[green.object_id] = conn
          conn
        else
          @pending.push green
          Green.hub.wait { @pending.delete green }
          acquire(green)
        end
      end

      # Release connection assigned to the supplied fiber and
      # resume any other pending connections (which will
      # immediately try to run acquire on the pool)
      def release(green)
        conn = @reserved.delete(green.object_id)
        @available.push(conn)

        if pending = @pending.shift
          Green.hub.callback { pending.switch }
        end
      end

      # Allow the pool to behave as the underlying connection
      #
      # If the requesting method begins with "a" prefix, then
      # hijack the callbacks and errbacks to fire a connection
      # pool release whenever the request is complete. Otherwise
      # yield the connection within execute method and release
      # once it is complete (assumption: fiber will yield until
      # data is available, or request is complete)
      #
      def method_missing(method, *args, &blk)
        execute do |conn|
          conn.__send__(method, *args, &blk)
        end
      end
  end

end