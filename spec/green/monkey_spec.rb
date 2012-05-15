# require 'spec_helper'
# require 'green/monkey'

# describe "green/monkey" do
#   let(:server) { TCPServer.new("127.0.0.1", 2225) }
#   let(:client) { TCPSocket.open("127.0.0.1", 2225) }

#   after { server.close; client.close }
#   it "should read and write" do
#     Green.spawn do
#       server.listen(1)
#       c, a = server.accept
#       c.write "hello"
#       c.close
#     end

#     g = Green.spawn do
#       client.read.must_equal "hello"
#     end
#     g.join
#   end
# end