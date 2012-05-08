class Green
  class Semaphore
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
        rawlink { g.switch }
        Green.hub.switch
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
    end
  end
end