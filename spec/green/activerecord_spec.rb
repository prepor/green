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
    ActiveRecord::Base.establish_connection(
      :adapter => 'green_mysql2',
      :database => 'widgets',
      :username => 'root',
      :pool => 5
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

  # it "should fire sequential, synchronous requests within single green" do
  #   start = Time.now.to_f
  #   res = []

  #   res.push Widget.find_by_sql(QUERY)
  #   res.push Widget.find_by_sql(QUERY)

  #   (Time.now.to_f - start.to_f).must_be_within_epsilon DELAY * res.size, DELAY * res.size * 0.15
  #   res.size.must_equal 2
  # end

  it "should fire 100 requests" do
    pool = Green::Pool.new size: 40
    50.times do
      pool.spawn(Green::ActiveRecord::Green) do
        widget = Widget.create title: 'hi'
        widget.update_attributes title: 'hello'
        puts "AFTER!"
      end
    end
  end

  # it "should create widget" do
  #   EM.synchrony do
  #     establish_connection
  #     Widget.create
  #     Widget.create
  #     Widget.count.should eql(2)
  #     EM.stop
  #   end
  # end

  # it "should update widget" do
  #   EM.synchrony do
  #     establish_connection
  #     ActiveRecord::Base.connection.execute("TRUNCATE TABLE widgets;")
  #     widget = Widget.create title: 'hi'
  #     widget.update_attributes title: 'hello'
  #     Widget.find(widget.id).title.should eql('hello')
  #     EM.stop
  #   end
  # end

  # describe "transactions" do
  #   it "should work properly" do
  #     EM.synchrony do
  #       establish_connection
  #       EM::Synchrony::FiberIterator.new(1..50, 30).each do |i|
  #         widget = Widget.create title: "hi#{i}"
  #         ActiveRecord::Base.transaction do
  #           widget.update_attributes title: "hello"
  #         end
  #         ActiveRecord::Base.transaction do
  #           raise ActiveRecord::Rollback
  #         end
  #       end
  #       Widget.all.each do |widget|
  #         widget.title.should eq('hello')
  #       end
  #       EM.stop
  #     end
  #   end
  # end

end