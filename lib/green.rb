require 'fiber'
require 'pp'
require 'thread'

class Green
  VERSION = "0.0.1"
  class Proxy
    attr_reader :f
    def initialize
      @f = Fiber.current
    end

    def switch(*args)
      f.transfer(*args)
    end
  end

  class SocketWaiter
    attr_reader :socket, :readers, :writers
    def initialize(socket)
      @socket = socket
      @readers = []
      @writers = []
    end

    def wait_read
      g = Green.current
      @readers << g
      Green.hub.wait { @readers.delete g }
    end

    def wait_write
      g = Green.current
      @writers << g
      Green.hub.wait { @writers.delete g }
    end

    def cancel
      
    end
  end

  module Waiter
    def green_cancel
      raise "override"
    end
  end

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
        g.throw Timeout::Error.new
      end
      res = blk.call
      timer.cancel
      res
    end
  end

  # class GreenError < StandardError; end
  # class GreenKill < GreenError; end

  require 'green/ext'
  require 'green/hub'

  require 'green/hub/em'

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

  # def kill
  #   self.throw(GreenKill.new)
  # end

  MAIN = Fiber.current[:green] = Proxy.new
end