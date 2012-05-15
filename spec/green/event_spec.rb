require 'spec_helper'
require 'green/event'
require 'green/group'
describe Green::Event do
  let(:e) { Green::Event.new }
  let(:g) { Green::Group.new }
  it "should wakeup all greens" do
    i = 0
    5.times do
      g.spawn { e.wait; i += 1}
    end
    i.must_equal 0
    e.set
    g.join
    i.must_equal 5
  end

  describe "set before wait" do
    it "should work properly" do
      e.set(:ok)
      e.wait.must_equal :ok
    end
  end
end