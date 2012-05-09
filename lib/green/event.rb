class Green
  class Event
    include Green::Waiter
    attr_reader :waiters
    def initialize
      @waiters = []
      @setted = false
    end

    def set(result = nil)
      @setted = true
      @result = result
      waiters.each { |v| Green.hub.callback { v.switch } }
    end

    def wait
      if @setted
        @result
      else
        waiters << Green.current
        Green.hub.wait self, Green.current
      end
    end

    def green_cancel(waiter)
      waiters.delete waiter
    end
  end
end