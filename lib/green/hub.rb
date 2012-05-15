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

    def wait(proc = nil, &cancel_clb)
      switch
    rescue => e
      (proc || cancel_clb).call
      raise e
    end

    def sleep(n)
      g = Green.current
      t = timer(n) { g.switch }
      wait { t.green_cancel }
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

    def socket_waiter(socket)
      raise "override"
    end
  end
end