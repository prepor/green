require 'socket'

# require 'eventmachine'
# require 'fiber'
# f1, f2 = nil, nil
# f1 = Fiber.new do
#   EM.next_tick { puts "f1 tick"; f2.transfer }
#   EM.run
# end

# f2 = Fiber.new do
#   puts "START F2"
#   EM.next_tick { puts "f2 tick"; f1.transfer }
#   EM.run
# end

# f1.resume


begin
  s1 = Socket.new(:INET, :STREAM, 0)

  s2 = Socket.new(:INET, :STREAM)

  s1.bind(Addrinfo.tcp("127.0.0.1", 2223))
  s1.listen 1

  Thread.new do
    s2.connect(Addrinfo.tcp("127.0.0.1", 2223))
  end

  Thread.new do
    while (r = s1.accept_nonblock)
      c, a = r
      c.recv(200)
    end
  end.join

ensure
  s1.close
  s2.close
end


    concurrency = 2
    urls = ['http://url.1.com', 'http://url2.com']
    results = []

    EM::Synchrony::FiberIterator.new(urls, concurrency).each do |url|
        resp = EventMachine::HttpRequest.new(url).get
    results.push resp.response
    end

    p results # all completed requests


g = Pool.new(size: 2)

urls = ['http://url.1.com', 'http://url2.com']

results = g.enumerator(urls) do |url|
  EventMachine::HttpRequest.new(url).get
end.map { |i| i }

p results


e = Enumerator.new do |y| 
  i = 0
  while i < 10 
    y << i
    i += 1
  end
end