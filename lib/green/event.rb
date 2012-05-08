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
        waiters << Green.current
        Green.hub.switch
      end
    end
  end
end