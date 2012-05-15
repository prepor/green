require 'spec_helper'
require 'green/socket'
describe Green::Socket do
  let(:s1) { Green::Socket.new(:INET, :STREAM, 0).tap { |s| s.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1) } }
  let(:s2) { Green::Socket.new(:INET, :STREAM, 0) }

  after do 
    s1.close
    s2.close
  end
  it "should read and write" do
    Green.spawn do
      s1.bind(Addrinfo.tcp("127.0.0.1", 2225))
      s1.listen(1)
      c, a = s1.accept
      c.write "hello"
      c.close
    end

    g = Green.spawn do
      s2.connect(Addrinfo.tcp("127.0.0.1", 2225))
      s2.read.must_equal "hello"
    end
    g.join
  end
end