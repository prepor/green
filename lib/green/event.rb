class Green
  class Event
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
        g = Green.current
        waiters << g
        Green.hub.wait { waiters.delete g }
      end
    end
  end
end