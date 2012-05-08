require 'fiber'
require 'pp'
require 'thread'

require 'green/ext'
require 'green/hub'

require 'green/hub/em'
class Green  
  class << self
    
    def thread_locals
      @thread_locals ||= {}
      @thread_locals[Thread.current] ||= {}
    end

    def sleep(n)
      Green.hub.sleep(n)
    end

    def main
      MAIN
    end

    def current
      Fiber.current[:green] || Proxy.new
    end

    def make_hub
      Hub::EM.new
    end

    def hub
      # thread_locals[:hub] ||= make_hub
      @hub ||= make_hub
    end

    def spawn(&blk)
      Green.new(&blk).tap { |o| o.start }
    end

    def timeout(n, &blk)
      g = current
      timer = hub.timer(n) do
        g.switch Timeout::Error.new
      end
      res = blk.call
      timer.cancel
      res
    end
  end

  class Proxy
    attr_reader :f
    def initialize
      @f = Fiber.current
    end

    def switch(*args)
      f.transfer(*args)
    end
  end


  attr_reader :f, :callbacks
  def initialize()
    @callbacks = []
    @f = Fiber.new do
      res = yield
      @callbacks.each { |c| c.call(*res) }
      Green.hub.switch
    end
    @f[:green] = self
  end

  def switch(*args)
    return unless f.alive?
    f.transfer(*args).tap do |*res|
      res.size == 1 && res.first.is_a?(Exception) && raise(res.first)
    end
  end

  def throw(exc = RuntimeException.new)
    switch(exc)
  end

  def start
    Green.hub.callback { self.switch }
  end

  def callback(&blk)
    callbacks << blk
  end

  def join
    g = Green.current
    callback { |*res| g.switch(*res) }
    Green.hub.switch
  end

  MAIN = Fiber.current[:green] = Proxy.new
end