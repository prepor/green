require "spec_helper"
require "green/mysql2"
require "green/connection_pool"
require "green/group"

describe Green::Mysql2 do

  DELAY = 0.25
  QUERY = "SELECT sleep(#{DELAY}) as mysql2_query"

  it "should support queries" do
    res = []
    db = Green::Mysql2::Client.new
    res = db.query QUERY

    res.first.keys.must_include "mysql2_query"
  end

  it "should fire sequential, synchronous requests" do
    db = Green::Mysql2::Client.new

    start = Time.now.to_f
    res = []

    res.push db.query QUERY
    res.push db.query QUERY
    (Time.now.to_f - start.to_f).must_be_within_epsilon DELAY * res.size, DELAY * res.size * 0.15
  end

  it "should fire simultaneous requests via pool" do
    db = Green::ConnectionPool.new(size: 2) do
      Green::Mysql2::Client.new
    end

    start = Time.now.to_f

    g = Green::Group.new
    g.spawn { db.query(QUERY) }
    g.spawn { db.query(QUERY) }
    res = g.join

    (Time.now.to_f - start.to_f).must_be_within_epsilon DELAY, DELAY * 0.30
    res.size.must_equal 2
  end

  it "should raise Mysql::Error in case of error" do
    db = Green::Mysql2::Client.new
    proc {
      db.query("SELECT * FROM i_hope_this_table_does_not_exist;")
    }.must_raise(Mysql2::Error)
  end
end