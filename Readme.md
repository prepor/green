Cooperative multitasking for Ruby. Proof of concept.

Based on Ruby 1.9 Fibers, but unlike EM::Synchrony it uses symmetric coroutines (only #current and #transfer used) and HUB-orientend architecture. So coroutines transfer control to HUB and HUB transfer control to coroutines. Coroutines never tranfer control to each other.

In comparison with EM-Synchrony it allows:
- develop real complex cooperative multitasking apps;
- timeouts. Yes, in common case you cannot add timeout with EM-Synchrony;
- kill greens. And it safe unlike kill Threads;
- works with REPL and debugger. EM-Synchrony uses Fiber.yield, so you cannot run  nothing in REPL;
- works with every environment. You can run nonblock web-applications with Unicorn;
- compatible with Ruby's Enumerator and with any other uses of Fibers themself (see https://github.com/igrigorik/em-synchrony/issues/114)

```ruby
require 'green'
require 'green/group'
require 'green-em/em-http'

g = Green::Pool.new(size: 2)

urls = ['http://google.com', 'http://yandex.ru']

results = g.enumerator(urls) do |url|
  EventMachine::HttpRequest.new(url).get
end.map { |i| i.response }

p results
```

You can run it from Irb! ;)

You can add timeout:

```ruby
require 'green'
require 'green/group'
require 'green-em/em-http'

g = Green::Pool.new(size: 2)

urls = ['http://google.com', 'http://yandex.ru']

begin
  Green.timeout(1) do
    results = g.enumerator(urls) do |url|
      EventMachine::HttpRequest.new(url).get
    end.map { |i| i.response }
    p results
  end
rescue Timeout::Error
  p "Timeout!"
end
```

And much more soon ;)

