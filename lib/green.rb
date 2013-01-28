require 'fiber'
require 'pp'
require 'thread'

class Green
  VERSION = "0.1.1"


  module GreenMethods
    def switch(*args)
      f.transfer(*args).tap do |*res|
        if res.size == 1 && res.first.is_a?(ThrowException)
          raise(res.first.exc)
        end
      end
    end

    def throw(exc = RuntimeException.new)
      Green.hub.callback { switch(ThrowException.new exc) }
    end

    def kill
      self.throw(GreenKill.new)
    end

    def locals
      f.local_fiber_variables
    end

    def [](name)
      locals[name]
    end

    def []=(name, val)
      locals[name] = val
    end

    def schedule(*args)
      Green.hub.callback { self.switch(*args) }
    end

    alias call schedule
  end

  class Proxy
    include GreenMethods
    attr_reader :f
    def initialize
      @f = Fiber.current
    end

    def alive?
      f.alive?
    end
  end

  class SocketWaiter
    attr_reader :socket
    def initialize(socket)
      @socket = socket
    end

    def wait_read
    end

    def wait_write
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
      hub_name = ENV['GREEN_HUB'] || 'Nio4r'
      Hub.const_get(hub_name.to_sym).new
      # Hub::Nio4r.new
      # Hub::EM.new
    end

    def hub
      # thread_locals[:hub] ||= make_hub
      @hub ||= make_hub
    end

    def spawn(&blk)
      new(&blk).tap { |o| o.start }
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

    def list_hash
      @list_hash ||= {}
    end

    def list
      list_hash.values
    end

    def init
      hub
    end
  end

  class GreenError < StandardError; end
  class GreenKill < GreenError; end

  class ThrowException < Struct.new(:exc); end

  require 'green/ext'
  require 'green/hub'

  require 'green/hub/em'
  require 'green/hub/nio4r'

  include GreenMethods

  attr_reader :f, :callbacks
  def initialize
    @callbacks = []
    @alive = true
    Green.list_hash[self] = self
    @f = Fiber.new do
      begin
        res = yield
      rescue GreenKill => e
      end
      @alive = false
      @callbacks.each { |c|
        c.call(res)
      }
      Green.list_hash.delete self
      Green.hub.switch
    end
    @f[:green] = self
  end

  def alive?
    @alive
  end

  def start
    Green.hub.callback { self.switch }
  end

  def callback(cb=nil, &blk)
    cb ||= blk
    if alive?
      callbacks << cb
    else
      Green.hub.callback(cb)
    end
  end

  def join
    g = Green.current
    callback { |res| Green.hub.callback { g.switch(res) } }
    Green.hub.switch
  end

  MAIN = Fiber.current[:green] = Proxy.new
end
