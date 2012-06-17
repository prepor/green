require 'green'
require 'active_record'
require 'active_record/connection_adapters/abstract/connection_pool'
require 'active_record/connection_adapters/abstract_adapter'
require 'green/semaphore'
require 'green/connection_pool'

suppress_warnings do
  ::Thread = Green
  ::Mutex = Green::Mutex
  ::ConditionVariable = Green::ConditionVariable
end

class Green
  class ActiveRecord < ::Green
    def initialize
      super
      callback { ::ActiveRecord::Base.clear_active_connections! }
    end
  end
end
