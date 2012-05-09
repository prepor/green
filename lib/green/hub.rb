class Green
  class Hub
    attr_reader :g
    def initialize
      c = Green.current
      callback { c.switch }      
      @g = Green.new do
        run
      end
      g.switch
    end

    def switch
      g.switch
    end

    def wait(waiter, *args)
      switch
    rescue => e
      waiter.green_cancel(*args)
      raise e
    end

    def sleep(n)
      g = Green.current
      t = timer(n) { g.switch }
      wait t
    end

    def run
      raise "override"
    end

    def timer(n, &blk)
      raise "override"
    end

    def callback(&blk)
      raise "override"
    end
  end
end