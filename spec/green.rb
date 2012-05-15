require 'spec_helper'

describe Green do
  describe ".spawn" do
    it "should spawn greens" do
      g = Green.spawn do
        :hello
      end
      g.join.must_equal :hello
    end
  end
end