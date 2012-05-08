require 'bundler'

Bundler.setup

$:.unshift(File.expand_path('../lib', __FILE__))

# Thread.current[:hello] = "foo"

# puts Thread.current[:hello]
# require 'eventmachine'
# Fiber.new do
#   EM.run do
#     puts Thread.current[:hello]
#     EM.stop
#   end
# end.resume

require 'green'

# g = Green.spawn do
#   puts "before sleep!"
#   Green.timeout(2) do
#     Green.sleep 3
#   end
#   puts "after sleep!"
#   "foo"
# end

# Green.spawn do
#   puts "ok!"
# end

# begin
#   puts "G: #{g.join}"
# rescue Timeout::Error => e
#   puts "Timeout!"
# end

# Green.sleep 2

# puts "Completed!"


# start = Time.now
# Green.sleep 1
# puts "Time: #{Time.now - start}"

# start = Time.now
# g = Green.spawn do
#   puts "Current: #{Green.current}"
#   enum = Enumerator.new do |y|
#     3.times do |i|
#       puts "Current: in EN #{Green.current}"
#       Green.sleep 1
#       y.yield i
#     end
#   end
#   puts enum.next
#   puts enum.next
# end
# g.join
# puts "Time: #{Time.now - start}"


require 'green/group'
require 'green-em/em-http'

g = Green::Pool.new(size: 2)

urls = ['http://google.com', 'http://yandex.ru']

results = g.enumerator(urls) do |url|
  puts url
  EventMachine::HttpRequest.new(url).get
end.map { |i| i.response }

p results