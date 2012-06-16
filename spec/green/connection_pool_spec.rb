require 'spec_helper'
require 'green/connection_pool'
require 'green/mysql2'
require 'green/group'

DELAY = 0.25
QUERY = "select sleep(#{DELAY})"

describe Green::ConnectionPool do

  
  let(:pool) { Green::ConnectionPool.new(size: size) { Green::Mysql2::Client.new } }

  describe "pool size is exceeded" do
    let(:size) { 1 }
    it "should queue requests" do
      start = Time.now.to_f

      g = Green::Group.new
      g.spawn { pool.query(QUERY) }
      g.spawn { pool.query(QUERY) }
      res = g.join

      (Time.now.to_f - start.to_f).must_be_within_epsilon DELAY * 2, DELAY * 2 * 0.15
      res.size.must_equal 2
    end
  end

  describe "pool size is enough" do
    let(:size) { 2 }
    it "should parallel requests" do
      start = Time.now.to_f

      g = Green::Group.new
      g.spawn { pool.query(QUERY) }
      g.spawn { pool.query(QUERY) }
      res = g.join

      (Time.now.to_f - start.to_f).must_be_within_epsilon DELAY, DELAY * 0.2
      res.size.must_equal 2
    end
  end
end