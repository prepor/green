# AR adapter for using a green mysql2 connection
# Just update your database.yml's adapter to be 'green_mysql2'

require 'green/mysql2'
require 'green/activerecord'
require 'active_record/connection_adapters/mysql2_adapter'

# module ActiveRecord
#   class Base
#     def self.green_mysql2_connection(config)
#       client = Green::ActiveRecord::ConnectionPool.new(size: config[:pool]) do
#         conn = ActiveRecord::ConnectionAdapters::GreenMysql2Adapter::Client.new(config.symbolize_keys)
#         # From Mysql2Adapter#configure_connection
#         conn.query_options.merge!(:as => :array)

#         # By default, MySQL 'where id is null' selects the last inserted id.
#         # Turn this off. http://dev.rubyonrails.org/ticket/6778
#         variable_assignments = ['SQL_AUTO_IS_NULL=0']
#         encoding = config[:encoding]
#         variable_assignments << "NAMES '#{encoding}'" if encoding

#         wait_timeout = config[:wait_timeout]
#         wait_timeout = 2592000 unless wait_timeout.is_a?(Fixnum)
#         variable_assignments << "@@wait_timeout = #{wait_timeout}"

#         conn.query("SET #{variable_assignments.join(', ')}")
#         conn
#       end 
#       options = [config[:host], config[:username], config[:password], config[:database], config[:port], config[:socket], 0]
#       ActiveRecord::ConnectionAdapters::GreenMysql2Adapter.new(client, logger, options, config)
#     end
#   end

#   module ConnectionAdapters
#     class GreenMysql2Adapter < ::ActiveRecord::ConnectionAdapters::Mysql2Adapter

#       class Column < AbstractMysqlAdapter::Column # :nodoc:
#         def adapter
#           GreenMysql2Adapter
#         end
#       end

#       ADAPTER_NAME = 'GreenMysql2'

#       class Client < Green::Mysql2::Client
#         include Green::ActiveRecord::Client
#       end

#       include Green::ActiveRecord::Adapter

#       def connect
        
#       end
#     end
#   end
# end



module ActiveRecord
  class Base
    def self.green_mysql2_connection(config)
      config[:username] = 'root' if config[:username].nil?

      if Mysql2::Client.const_defined? :FOUND_ROWS
        config[:flags] = Mysql2::Client::FOUND_ROWS
      end

      client = Green::Mysql2::Client.new(config.symbolize_keys)
      options = [config[:host], config[:username], config[:password], config[:database], config[:port], config[:socket], 0]
      ConnectionAdapters::GreenMysql2Adapter.new(client, logger, options, config)
    end
  end

  module ConnectionAdapters
    class GreenMysql2Adapter < ::ActiveRecord::ConnectionAdapters::Mysql2Adapter

      class Column < AbstractMysqlAdapter::Column # :nodoc:
        def adapter
          GreenMysql2Adapter
        end
      end

      ADAPTER_NAME = 'GreenMysql2'

      def connect
        @connection = Green::Mysql2::Client.new(@config)
        configure_connection
      end
    end
  end
end