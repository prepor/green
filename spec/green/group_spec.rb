require 'spec_helper'
require 'green/group'
require 'green/event'
require 'set'
describe Green::Group do
  let(:g) { Green::Group.new }

  it "should wait each task" do
    result = ""
    g.spawn { result << "fiz" }
    g.spawn { result << "baz" }
    g.join
    result.must_equal "fizbaz"
  end

  describe "apply" do
    it "should wait result" do
      g.apply { :foo }.must_equal :foo
    end
  end

  describe "enumerator" do
    it "should return enumerator" do
      en = g.enumerator([1, 2, 3]) { |o| o }
      en.must_be_instance_of Enumerator
      en.map { |o| o }.must_equal [1, 2, 3]
    end
  end
end

describe Green::Pool do
  let(:e1) { Green::Event.new }
  let(:e2) { Green::Event.new }
  let(:p) { Green::Pool.new size: 1}

  it "should wait each task" do
    result = ""
    p.spawn { result << "fiz"; Green.sleep(0) }
    Green.spawn { p.spawn { result << "baz"; Green.sleep(0) } }
    p.join
    result.must_equal "fizbaz"
  end

  # ugly test :(
  it "should block after limit" do
    i = 0
    p.spawn { i += 1; e1.set; e2.wait }
    Green.spawn { p.spawn { i += 1 } }
    p.size.must_equal 1
    e1.wait
    i.must_equal 1
    Green.sleep(0)
    i.must_equal 1
    p.size.must_equal 1
    e2.set
    p.join
    i.must_equal 2
  end
end

