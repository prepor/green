require 'green/event'
require 'green/semaphore'
class Green
  class Group
    attr_reader :options, :greens
    def initialize(options = {})
      @options = options
      @options[:klass] ||= ::Green
      @greens = []
    end

    def spawn(*args, &blk)
      g = @options[:klass].spawn do
        blk.call(*args)
      end
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
      while (g = greens.first)
        g.join
      end
    end

    def kill
      greens.each(&:kill)
    end

    def size
      greens.size
    end

    def enumerator(iterable, &blk)
      iter = iterable.each
      Enumerator.new do |y|
        e = Event.new
        begin
          waiting = 0
          while true
            i = iter.next
            waiting += 1
            spawn(i) do |item|
              y << blk.call(item)
              waiting -= 1
              e.set if waiting == 0
            end
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
      raise ArgumentError.new("Undefined option :size") unless options[:size]
      @semaphore = Semaphore.new(options[:size])
    end

    def spawn(*args, &blk)
      semaphore.acquire
      super() do
        begin
          blk.call(*args)
        ensure
          semaphore.release
        end
      end
    end

    def join
      semaphore.wait
    end
  end
end
