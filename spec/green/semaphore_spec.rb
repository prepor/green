require 'spec_helper'
require 'green/semaphore'
require 'green/event'
require 'green/group'

describe Green::Mutex do
  let(:m) { Green::Mutex.new }
  it "should synchronize" do
    e = Green::Event.new
    i = 0
    Green.spawn do
      m.synchronize do
        e.wait
        i += 1
      end
    end
    Green.spawn do
      e.set
      m.synchronize do
        i.must_equal 1
      end
    end.join
  end

  describe "lock" do
    describe "when mutex already locked" do
      it "should raise GreenError" do
        proc {
          m.lock
          m.lock
        }.must_raise Green::GreenError
      end
    end
  end

  describe "sleep" do
    describe "without timeout" do
      it "should sleep until switch" do
        m.lock
        i = 0
        g = Green.current
        Green.hub.callback { i += 1; g.switch }
        res = m.sleep
        i.must_equal 1
      end

      it "should release lock" do
        i = 0
        e = Green::Event.new
        group = Green::Group.new
        g1 = group.spawn do 
          m.lock
          e.wait
          i += 1
          m.sleep
        end
        group.spawn do
          e.set
          m.lock
          i.must_equal 1
          m.unlock
          Green.hub.callback { g1.switch }
        end
        group.join
      end

      it "should wait unlock after switch" do
        i = 0
        group = Green::Group.new
        g1 = group.spawn do 
          m.lock
          m.sleep
          i.must_equal 1
        end
        group.spawn do 
          m.lock          
          i += 1
          m.unlock
          Green.hub.callback { g1.switch }
        end
        group.join
      end
    end
      
    describe "with timeout" do
      it "should sleep for timeout" do
        m.lock
        i = 0
        Green.hub.callback { i += 1 }
        m.sleep(0.1)
        i.must_equal 1
      end
      describe "and resume before timeout" do
        it "should not raise any execptions" do
          m.lock
          g = Green.current
          Green.hub.callback { g.switch }
          m.sleep(0.05)
          Green.spawn { Green.sleep(0.1) }.join
        end
        it "should resume in nested Green" do
          Green.spawn do
            m.synchronize do
              t = m.sleep(0.05)
              t.must_be :>=, 0.05
            end
          end.join
        end
      end
    end
  end
  describe Green::ConditionVariable do
    let(:c){ Green::ConditionVariable.new }
    it "should wakeup waiter" do
      i = ''
      g = Green::Group.new
      g.spawn do
        m.synchronize do
          i << 'a'
          c.wait(m)
          i << 'c'
        end
      end
      g.spawn do
        i << 'b'
        c.signal
      end
      g.join
      i.must_equal 'abc'
    end

    it 'should allow to play ping-pong' do
      i = ''
      g = Green::Group.new
      g.spawn do
        m.synchronize do
          i << 'pi'
          c.wait(m)
          i << '-po'
          c.signal
        end
      end
      g.spawn do
        m.synchronize do
          i << 'ng'
          c.signal
          c.wait(m)
          i << 'ng'
        end
      end
      g.join
      i.must_equal 'ping-pong'
    end
    it 'should not raise, when timer wakes up green between `signal` and `next_tick`' do
      e = Green::Event.new
      g = Green.spawn do
        m.synchronize do
          c.wait(m, 0.0001)
        end
      end
      Green.hub.callback do
        c.signal
        Green.hub.callback { e.set }
      end
      e.wait
      g.join
    end
  end
end