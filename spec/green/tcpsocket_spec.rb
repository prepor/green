# based on https://github.com/igrigorik/em-synchrony/pull/127

require 'spec_helper'
require 'green/socket'
require 'green/group'
require 'green/event'
describe Green::TCPSocket do
  describe '.new' do
    describe 'to an open TCP port on an resolvable host' do
      it 'succeeds'  do
        Green.spawn do
          s = Green::TCPServer.new '127.0.0.1', 12345
          s.accept
          s.close
        end
        Green.spawn do
          s = Green::TCPSocket.new '127.0.0.1', 12345
          s.close
        end.join
      end
    end

    describe 'to an unresolvable host' do
      it 'raises SocketError' do
        proc {
          Green::TCPSocket.new 'xxxyyyzzz', 12345
        }.must_raise SocketError
      end
    end

    describe 'to a closed TCP port' do
      it 'raises Errno::ECONNREFUSED' do
        proc {
          Green::TCPSocket.new '127.0.0.1', 12345
        }.must_raise Errno::ECONNREFUSED
      end
    end
  end

  def in_connect(&blk)
    server = Green::TCPServer.new '127.0.0.1', 12345
    s = nil
    client = nil
    g = Green::Group.new
    g.spawn do
      s = server.accept
      s.write '1234'      
    end
    g.spawn do 
      client = Green::TCPSocket.new '127.0.0.1', 12345
    end
    g.join
    blk.call s, client
    s.close unless s.closed?
    client.close unless client.closed?
  ensure
    server.close
  end
  
  describe '#closed?' do
    describe 'after calling #close' do
      it 'returns true' do
        in_connect do |s, c|
          c.close
          c.closed?.must_equal true
        end
      end
    end
    describe 'after the peer has closed the connection' do
      describe 'when we\'ve not yet read EOF' do
        it 'returns false' do
          in_connect do |s, c|
            s.close
            c.read(2).size.must_equal 2
            c.closed?.must_equal false
          end
        end
      end
      describe 'when we\'ve read EOF' do
        it 'returns false' do
          in_connect do |s, c|
            s.close
            c.read(10).size.must_equal 4
            c.read(10).must_equal nil
            c.closed?.must_equal false
          end
        end
      end
    end
  end
  
  describe '#read' do
    describe 'with a length argument' do
      describe 'with a possitive length argument' do
        describe 'when the connection is open' do
          describe 'with greater or equal than the requested data buffered' do
            it 'returns the requested data and no more' do
              in_connect do |s, c|
                c.read(2).size.must_equal 2
                c.read(1).size.must_equal 1
              end
            end
          end
          describe 'with less than the requested data buffered' do
            it 'blocks' do
              in_connect do |s, c|
                blocked = true
                g = Green.spawn { blocked.must_equal true; s.close }
                res = c.read(10)
                blocked = false
                g.join
              end
            end
          end
        end
        describe 'when the peer has closed the connection' do
          describe 'with no data buffered' do
            it 'returns nil' do
              in_connect do |s, c|
                s.close
                c.read(4).size.must_equal 4
                c.read(1).must_equal nil
              end
            end
          end
          describe 'with less than the requested data buffered' do
            it 'returns the buffered data' do
              in_connect do |s, c|
                s.close
                c.read(50).size.must_equal 4
              end
            end
          end
          describe 'with greater or equal than the requested data buffered' do
            it 'returns the requested data and no more' do
              in_connect do |s, c|
                c.read(2).size.must_equal 2
              end
            end
          end
        end
        describe 'when we closed the connection' do
          it 'raises IOError' do
            in_connect do |s, c|
              c.close
              proc {
                c.read(4)
              }.must_raise IOError
            end
          end
        end
      end
      describe 'with a negative length argument' do
        it 'raises ArgumentError' do
          in_connect do |s, c|
            proc {
              c.read(-10)
            }.must_raise ArgumentError
          end
        end
      end
      describe 'with a zero length argument' do
        describe 'when the connection is open' do
          it 'returns an empty string' do
            in_connect do |s, c|
              c.read(0).must_equal ""
            end
          end
        end
        describe 'when the peer has closed the connection' do
          it 'returns an empty string' do
            in_connect do |s, c|
              s.close
              c.read(0).must_equal ""
            end
          end
        end
        describe 'when we closed the connection' do
          it 'raises IOError' do
            in_connect do |s, c|
              c.close
              proc {
                c.read(0)
              }.must_raise IOError
            end
          end
        end
      end
    end
    describe 'without a length argument' do
      describe 'when the connection is open' do
        it 'blocks until the peer closes the connection and returns all data sent' do
          in_connect do |s, c|
            blocked = true
            Green.hub.timer(0.01) { blocked.must_equal true; s.close }
            c.read(10).must_equal '1234'
            blocked = false
          end
        end
      end
      describe 'when the peer has closed the connection' do
        describe 'with no data buffered' do
          it 'returns an empty string' do
            in_connect do |s, c|
              s.close
              c.read
              c.read.must_equal ""
            end
          end
        end
        describe 'with data buffered' do
          it 'returns the buffered data' do
            in_connect do |s, c|
              s.close
              c.read.must_equal "1234"
            end
          end
        end
      end
      describe 'when we closed the connection' do
        it 'raises IOError' do
          in_connect do |s, c|
            c.close
            proc {
              c.read
            }.must_raise IOError
          end
        end
      end
    end
  end
  
  describe '#recv' do
    describe 'with a length argument' do
      describe 'with a positive length argument' do
        describe 'when the connection is open' do
          describe 'with greater or equal than the requested data buffered' do
            it 'returns the requested data and no more' do
              in_connect do |s, c|
                c.recv(2).size.must_equal 2
                c.recv(1).size.must_equal 1
              end
            end
          end
          describe 'with less than the requested data buffered' do
            it 'return the buffered data' do
              in_connect do |s, c|
                c.recv(50).size.must_equal 4
              end
            end
          end
          describe 'with no buffered data' do
            it 'blocks' do
              in_connect do |s, c|
                c.recv(10)
                blocked = true
                g = Green.spawn do
                  blocked.must_equal true
                  s.close
                end
                c.recv(10)                
                blocked = false
                g.join
              end
            end
          end
        end
        describe 'when the peer has closed the connection' do
          describe 'with no data buffered' do
            it 'returns an empty string' do
              in_connect do |s, c|
                s.close
                c.read(4).size.must_equal 4
                c.recv(1).must_equal ""
              end
            end
          end
          describe 'with less than the requested data buffered' do
            it 'returns the buffered data' do
              in_connect do |s, c|
                s.close
                c.recv(50).size.must_equal 4
              end
            end
          end
          describe 'with greater or equal than the requested data buffered' do
            it 'returns the requested data and no more' do
              in_connect do |s, c|
                s.close
                c.recv(2).size.must_equal 2
              end
            end
          end
        end
        describe 'when we closed the connection' do
          it 'raises IOError' do
            in_connect do |s, c|
              c.close
              proc {
                res = c.recv(4)
              }.must_raise IOError
            end
          end
        end
      end
      describe 'with a negative length argument' do
        it 'raises ArgumentError' do
          in_connect do |s, c|
            proc {
              c.recv(-10)
            }.must_raise ArgumentError
          end
        end
      end
      describe 'with a zero length argument' do
        describe 'when the connection is open' do
          it 'returns an empty string' do
            in_connect do |s, c|
              c.recv(0).must_equal ""
            end
          end
        end
        describe 'when the peer has closed the connection' do
          it 'returns an empty string' do
            in_connect do |s, c|
              s.close
              c.recv(0).must_equal ""
            end
          end
        end
        describe 'when we closed the connection' do
          it 'raises IOError' do
            in_connect do |s, c|
              c.close
              proc {
                c.recv(0)
              }.must_raise IOError
            end
          end
        end
      end
    end
    describe 'without a length argument' do
      it 'raises ArgumentError' do
        in_connect do |s, c|
          proc {
            c.recv()
          }.must_raise ArgumentError
        end
      end
    end
  end
  
  describe '#write' do
    describe 'when the peer has closed the connection' do
      it 'raises Errno::EPIPE' do
        in_connect do |s, c|
          s.close
          Green.spawn do
            Green.sleep 0.01
            proc {
              c.write 100000.times.to_a * '' # on small chunks it can not raise exception
            }.must_raise Errno::EPIPE
          end.join
        end
      end
    end
    describe 'when we closed the connection' do
      it 'raises IOError' do
        in_connect do |s, c|
          c.close
          proc {
            c.write("foo")
          }.must_raise IOError
        end
      end
    end
  end
  
  describe '#send' do
    describe 'when the peer has closed the connection' do
      it 'raises Errno::EPIPE' do
        in_connect do |s, c|
          s.close
          Green.spawn do
            Green.sleep 0.01
            proc {
              c.send 100000.times.to_a * '', 0
            }.must_raise Errno::EPIPE
          end.join
        end
      end
    end

    describe 'when we closed the connection' do
      it 'raises IOError' do
        in_connect do |s, c|
          c.close
          proc {
            c.send "foo", 0
          }.must_raise IOError
        end
      end
    end

    describe 'without a flags argument' do
      it 'raises ArgumentError' do
        in_connect do |s, c|
          proc {
            c.send 'foo'
          }.must_raise ArgumentError
        end
      end
    end
  end

end