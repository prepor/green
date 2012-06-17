# DO NOT WORK

require "spec_helper"
require "green/activerecord"
require 'green/group'


# create database widgets;
# use widgets;
# create table widgets (
# id INT NOT NULL AUTO_INCREMENT,
# title varchar(255),
# PRIMARY KEY (`id`)
# );

class Widget < ActiveRecord::Base; end;

describe Green::ActiveRecord do
  DELAY = 0.25
  QUERY = "SELECT sleep(#{DELAY})"

  def establish_connection
    # ActiveRecord::Base.logger = Logger.new STDOUT
    ActiveRecord::Base.establish_connection(
      :adapter => 'green_mysql2',
      :database => 'widgets',
      :username => 'root',
      :pool => 50
    )
    Widget.delete_all
  end

  before do
    establish_connection
  end

  after do
    ActiveRecord::Base.connection_pool.disconnect!
  end

  it "should establish AR connection" do
    result = Widget.find_by_sql(QUERY)
    result.size.must_equal 1
  end

  it "should fire sequential, synchronous requests within single green" do
    start = Time.now.to_f
    res = []

    res.push Widget.find_by_sql(QUERY)
    res.push Widget.find_by_sql(QUERY)

    (Time.now.to_f - start.to_f).must_be_within_delta DELAY * res.size, DELAY * res.size * 0.15
    res.size.must_equal 2
  end

  # it "should fire 100 requests" do
  #   pool = Green::Pool.new size: 40, klass: Green::ActiveRecord
    
  #   100.times do
  #     pool.spawn do
  #       widget = Widget.create title: 'hi'
  #       widget.update_attributes title: 'hello'
  #     end
  #   end
  #   pool.join
  # end

  it "should create widget" do
    Widget.create
    Widget.create
    Widget.count.must_equal 2
  end

  it "should update widget" do
    widget = Widget.create title: 'hi'
    widget.update_attributes title: 'hello'
    Widget.find(widget.id).title.must_equal 'hello'
  end

  # describe "transactions" do
  #   it "should work properly" do
  #     pool = Green::Pool.new size: 40, klass: Green::ActiveRecord
  #     50.times do |i|
  #       pool.spawn do
  #         widget = Widget.create title: "hello"
  #         ActiveRecord::Base.transaction do
  #           widget.update_attributes title: "hi#{i}"
  #           raise ActiveRecord::Rollback
  #         end
  #       end
  #     end
  #     pool.join
  #     Widget.all.each do |widget|
  #       widget.title.must_equal 'hello'
  #     end
  #   end
  # end

end