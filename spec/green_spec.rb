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

  describe "sleep" do
    it "should set sleep" do
      t = Time.now
      Green.spawn do
        Green.sleep 0.1
      end.join
      (Time.now - t).must_be :>, 0.1
    end
  end

  describe "timeouts" do
    it "should set timeout" do
      t = Time.now
      Green.spawn do
        begin
          Green.timeout(0.01) do
            Green.sleep 0.1
          end
        rescue Timeout::Error
        end
      end.join
      (Time.now - t).must_be :<, 0.1
    end
  end
end