begin
  require "em-http-request"
rescue LoadError => error
  raise "Missing EM-Synchrony dependency: gem install em-http-request"
end

module EventMachine
  class HTTPException < RuntimeError; end
  module HTTPMethods
     %w[get head post delete put].each do |type|
       class_eval %[
         alias :a#{type} :#{type}
         def #{type}(options = {}, &blk)
           g = Green.current

           conn = setup_request(:#{type}, options, &blk)
           if conn.error.nil?
             conn.callback { g.switch(conn) }
             conn.errback  { g.throw(HTTPException.new(conn)) }
             
             Green.hub.wait(conn)
           else
             raise HTTPException.new(conn)
           end
         end
      ]
    end
  end
end