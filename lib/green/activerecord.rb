require 'green'
require 'active_record'
require 'active_record/connection_adapters/abstract/connection_pool'
require 'active_record/connection_adapters/abstract_adapter'
require 'green/semaphore'
require 'green/connection_pool'

# suppress_warnings do
  ::Thread = Green
  ::Mutex = Green::Mutex
  ::ConditionVariable = Green::ConditionVariable
# end
class Green
  module ActiveRecord

  end
end
# module ActiveRecord
#   module ConnectionAdapters
#     class ConnectionPool
#       def connection
#         _fibered_mutex.synchronize do
#           @reserved_connections[current_connection_id] ||= checkout
#         end
#       end

#       def _fibered_mutex
#         @fibered_mutex ||= Green::Mutex.new
#       end
#     end
#   end
# end

# class Green
#   module ActiveRecord
#     module Client
#       def open_transactions
#         @open_transactions ||= 0
#       end

#       def open_transactions=(v)
#         @open_transactions = v
#       end

#       def acquired_for_connection_pool
#         @acquired_for_connection_pool ||= 0
#       end

#       def acquired_for_connection_pool=(v)
#         @acquired_for_connection_pool = v
#       end
#     end
    
#     module Adapter
#       def configure_connection
#         nil
#       end

#       def transaction(*args, &blk)
#         @connection.execute do |conn|
#           super
#         end
#       end

#       def real_connection
#         @connection.connection
#       end

#       def open_transactions
#         real_connection.open_transactions
#       end

#       def increment_open_transactions
#         real_connection.open_transactions += 1
#       end

#       def decrement_open_transactions
#         real_connection.open_transactions -= 1
#       end
#     end

#     class ConnectionPool < Green::ConnectionPool

#       # consider connection acquired
#       def execute
#         g = Green.current
#         conn = acquire(g)
#         begin          
#           conn.acquired_for_connection_pool += 1
#           yield conn
#         # ensure
#           conn.acquired_for_connection_pool -= 1
#           release(g) if conn.acquired_for_connection_pool == 0
#         end
#       end

#       def acquire(green)
#         return @reserved[green.object_id] if @reserved[green.object_id]
#         super
#       end

#       def connection
#         acquire(Green.current)
#       end
#     end
#   end
# end