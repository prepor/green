require 'green/event'
require 'green/semaphore'
class Green
  class Group
    attr_reader :options, :greens
    def initialize(options = {})      
      @options = options
      @greens = []
    end

    def spawn(&blk)
      g = Green.spawn(&blk)
      add g
      g.callback { discard g }
      g
    end

    def apply(&blk)
      spawn(&blk).join
    end

    def add(green)
      greens << green
    end

    def discard(green)
      greens.delete green
    end

    def join
      greens.each(&:join)
    end

    def enumerator(iterable, &blk)
      iter = iterable.each
      Enumerator.new do |y|
        e = Event.new
        begin
          waiting = 0
          while true
            i = iter.next
            puts "NEXT #{i}"
            waiting += 1
            spawn_clb = proc do 
              puts "SPAWNED #{i}, #{Fiber.current}"
              y << blk.call(i)
              waiting -= 1
              e.set if waiting == 0 
            end
            spawn(&spawn_clb)
          end          
        rescue StopIteration
          e.wait
        end
      end
    end
  end

  class Pool < Group
    attr_reader :semaphore
    def initialize(*args)
      super
      @semaphore = Semaphore.new(options[:size])
    end

    def spawn(&blk)
      semaphore.acquire
      super do
        begin
          blk.call
        ensure
          semaphore.release
        end
      end
    end
  end
end