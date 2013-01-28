require 'spec_helper'
require 'green/group'
require 'green/event'
require 'set'
describe Green::Group do
  let(:g) { Green::Group.new }

  describe "join" do
    it "should wait each task" do
      result = ""
      g.spawn { result << "fiz" }
      g.spawn { result << "baz" }
      g.join
      result.must_equal "fizbaz"
    end

    # it "return each result" do
    #   g.spawn { 1 }
    #   g.spawn { 2 }
    #   g.join.reduce(0, &:+).must_equal 3
    # end
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
  let(:size) { 1 }
  let(:p) { Green::Pool.new size: size }

  it "should wait each task" do
    result = ""
    p.spawn { result << "fiz"; Green.sleep(0) }
    Green.spawn { p.spawn { result << "baz"; Green.sleep(0) } }
    p.join
    result.must_equal "fizbaz"
  end

  describe "spawn attack" do
    let(:size) { 10 }
    it "should work correctly" do     
      i = 0
      100.times { p.spawn { i += 1 } }
      p.join
      i.must_equal 100
    end

    describe "with random timer" do
      it "should work correctly" do     
        i = 0
        100.times { p.spawn { Green.sleep(rand); i += 1 } }
        p.join
        i.must_equal 100
      end
    end
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

