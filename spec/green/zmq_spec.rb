# -*- coding: utf-8 -*-
require "spec_helper"
require 'green/zmq'
require 'green/group'

describe ZMQ::Socket do

  describe "simple case" do
    before do
      @ctx = ZMQ::Context.new
      @rep = @ctx.socket(ZMQ::REP)
      @req = @ctx.socket(ZMQ::REQ)
      @rep.bind('inproc://test')
      @req.connect('inproc://test')
    end

    after do
      @req.close
      @rep.close
      @ctx.terminate
    end

    it "works" do
      @req.send_string 'hello'
      Green.spawn do
        str = ''
        @rep.recv_string(str)
        str.must_equal 'hello'
      end.join
    end
  end

  # describe "complex topology" do
  #   let(:router_endpoint) { "tcp://127.0.0.1:12345" }
  #   let(:dealer_endpoint) { "tcp://127.0.0.1:12346" }
  #   before do
  #     @ctx = ZMQ::Context.new
  #     @router = @ctx.socket ZMQ::ROUTER
  #     @dealer = @ctx.socket ZMQ::DEALER
  #     @router.bind(router_endpoint)
  #     @dealer.bind(dealer_endpoint)
  #     @router_green = Green.spawn do
  #       begin
  #         strings = []
  #         while (@router.recv_strings(strings) == 0)
  #           @dealer.send_strings strings
  #           strings = []
  #         end
  #       ensure
  #         @router.close
  #       end
  #     end
  #     @dealer_green = Green.spawn do
  #       begin
  #         strings = []
  #         while (@dealer.recv_strings(strings) == 0)
  #           @router.send_strings strings
  #           strings = []
  #         end
  #       ensure
  #         @dealer.close
  #       end
  #     end
  #   end

  #   def spawn_workers
  #     @workers_ctx = ZMQ::Context.new
  #     @workers = Green::Group.new
  #     10.times.map do
  #       @workers.spawn do
  #         begin
  #           s = @workers_ctx.socket ZMQ::REP
  #           s.connect dealer_endpoint
  #           strings = []
  #           while (s.recv_strings(strings) == 0)
  #             s.send_string((strings.first.to_i + 1).to_s)
  #             strings = []
  #           end
  #         ensure
  #           s.close
  #         end
  #       end
  #     end
  #   end

  #   it "should increment numbers" do
  #     ctx = ZMQ::Context.new
  #     clients = Green::Group.new
  #     5.times do
  #       clients.spawn do
  #         s = ctx.socket ZMQ::REQ
  #         s.connect router_endpoint
  #         i = 0
  #         str = ''
  #         10.times do
  #           s.send_string i.to_s
  #           s.recv_string str
  #           i = str.to_i
  #         end
  #         s.close
  #         i.must_equal 10
  #       end
  #     end
  #     Green.spawn do
  #       Green.sleep 1
  #       spawn_workers
  #     end
  #     clients.join
  #     ctx.terminate
  #   end

  #   after do
  #     @workers.kill
  #     @router_green.kill
  #     @dealer_green.kill 
  #     # @ctx.terminate # FIXME
  #     # @workers_ctx.terminate
  #   end
  # end
end

