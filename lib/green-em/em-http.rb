begin
  require "em-http-request"
rescue LoadError => error
  raise "Missing EM-Synchrony dependency: gem install em-http-request"
end
require 'green-em'

module EventMachine
  class HTTPException < RuntimeError; end
  module HTTPMethods
     %w[get head post delete put].each do |type|
       class_eval %[
         alias :a#{type} :#{type}
         def #{type}(options = {}, &blk)
<<<<<<< HEAD
           g = Green.current
           conn = setup_request(:#{type}, options, &blk)
           if conn.error.nil?
             conn.callback { g.switch(conn) }
             conn.errback  { g.throw(HTTPException.new) }
             
             Green.hub.wait { conn.green_cancel }
=======
           conn = setup_request(:"#{type}", options, &blk)
           if conn.error.nil?
             Green::EM.sync conn, callback_args: [conn], errback_args: [HTTPException.new(conn)]
>>>>>>> - Green::EM.sync
           else
             raise HTTPException.new
           end
         end
      ]
    end
  end
end
