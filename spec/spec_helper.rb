require 'bundler'
ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
Bundler.setup

require 'minitest/spec'
require 'minitest/autorun'

require 'helpers'

require 'green'