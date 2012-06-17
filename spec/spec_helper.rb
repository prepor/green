require 'bundler'
ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
Bundler.setup

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'

require 'helpers'

require 'green'

MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new


# class MiniTest::Spec
#   def teardown
#     g = Green.current
#     Green.hub.callback { g.switch }
#     Green.hub.switch
#     puts "Callback: #{Green.hub.callbacks.size}; Timers: #{Green.hub.timers.size}; Cancels: #{Green.hub.cancel_timers.size}"
#     puts Green.hub.callbacks.inspect
#   end
# end

# at_exit {
#   loop do
#     MiniTest::Unit.new.run
#     break if MiniTest::Unit.runner.errors != 0
#   end
# }