require 'bundler'

Bundler.setup

require 'green'
require 'green/group'

app = proc do |env|
  start = Time.now
  g = Green::Group.new
  results = []
  g.spawn do
    Green.sleep 1
    results << :fiz
  end
  g.spawn do
    Green.sleep 1
    results << :buz
  end
  g.join
  [200, {"Content-Type" => 'plain/text'}, ["Execution time: #{Time.now - start}; Results: #{results.inspect}"]]
end

run app 