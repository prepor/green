class Green
  class Semaphore
    include Green::Waiter
    attr_accessor :counter, :value
    def initialize(value = 1)
      @value = value
      @counter = value
      @links = []
    end

    def wait_links
      @wait_links ||= []
    end

    def acquire
      if counter > 0
        self.counter -= 1
        true
      else
        g = Green.current
        clb = rawlink { g.switch }
        Green.hub.wait { unlink clb }
        self.counter -= 1
        true
      end
    end

    def release
      self.counter += 1
      wait_links.dup.each(&:call)
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

    def wait(v = value)
      if counter >= v
        return counter
      else
        g = Green.current
        clb = proc do 
          if counter >= v && @links.size == 0
            wait_links.delete clb
            Green.hub.callback { g.switch }            
          end
        end
        wait_links << clb
        Green.hub.wait { wait_links.delete clb }
      end
    end

    def wait_avaliable
      wait value - 1
    end

  end
end