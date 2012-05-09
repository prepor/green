class Green
  class Semaphore
    include Green::Waiter
    attr_accessor :counter
    def initialize(value = 1)
      @counter = value
      @links = []
    end

    def acquire
      if counter > 0
        self.counter -= 1
        true
      else
        g = Green.current
        clb = rawlink { g.switch }
        Green.hub.wait self, clb
        self.counter -= 1
        true
      end
    end

    def release
      self.counter += 1
      if @links.size > 0
        l = @links.pop
        Green.hub.callback { l.call }
      end
    end

    def rawlink(&clb)
      @links << clb
      clb
    end

    def unlink(clb)
      @links.delete clb
    end

    def green_cancel(clb)
      unlink clb
    end
  end
end