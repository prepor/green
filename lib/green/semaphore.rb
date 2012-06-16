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

  # With Ruby compatible API
  class Mutex < Semaphore
    def initialize
      super 1
      @slept = {}
    end

    def synchronize
      lock
      yield
    ensure
      unlock
    end

    def lock
      if Green.current.locals["mutex_locked_#{self.object_id}"]
        Green.current.locals.delete "mutex_locked_#{self.object_id}"
        raise Green::GreenError.new
      end
      Green.current.locals["mutex_locked_#{self.object_id}"] = true
      acquire
    end

    def unlock
      raise Green::GreenError.new unless Green.current.locals["mutex_locked_#{self.object_id}"]
      Green.current.locals.delete "mutex_locked_#{self.object_id}"
      release
    end

    def _wakeup(green)
      if @slept.delete(green)
        Green.hub.callback { green.switch }
      end
    end

    def sleep(timeout = nil)
      unlock    
      beg = Time.now
      current = Green.current
      @slept[current] = true
      begin
        if timeout
          t = Green.hub.timer(timeout) { _wakeup(current) }
          Green.hub.switch
          t.green_cancel
        else
          Green.hub.switch
        end
      ensure
        @slept.delete current
      end
      yield if block_given?
      lock
      Time.now - beg
    end
  end

  class ConditionVariable
    def initialize
      @waiters = []
    end

    #
    # Releases the lock held in +mutex+ and waits; reacquires the lock on wakeup.
    #
    # If +timeout+ is given, this method returns after +timeout+ seconds passed,
    # even if no other thread doesn't signal.
    #
    def wait(mutex, timeout=nil)
      current = Green.current
      pair = [mutex, current]
      @waiters << pair
      mutex.sleep timeout do
        @waiters.delete pair
      end
      self
    end

    def _wakeup(mutex, green)
      if alive = green.alive?
        Green.hub.callback {
          mutex._wakeup(green)
        }
      end
      alive
    end

    #
    # Wakes up the first thread in line waiting for this lock.
    #
    def signal
      while (pair = @waiters.shift)
        break if _wakeup(*pair)
      end
      self
    end

    #
    # Wakes up all threads waiting for this lock.
    #
    def broadcast
      @waiters.each do |mutex, green|
        _wakeup(mutex, green)
      end
      @waiters.clear
      self
    end
  end
end