require 'support/integration_helper'

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.profiles.define 'gem' do
    add_filter '/spec/'
    add_filter '/features/'
    add_filter '/vendor/'

    add_group 'Libraries', '/lib/'
  end

  SimpleCov.start 'gem'
end

require 'bundler/setup'
require 'vcloud/edge_gateway'
require 'vcloud/tools/tester'


if ENV['COVERAGE']
  SimpleCov.at_exit do
    SimpleCov.result.format!
    # do not change the coverage percentage, instead add more unit tests to fix coverage failures.
    if SimpleCov.result.covered_percent < 90
      print "ERROR::BAD_COVERAGE\n"
      print "Coverage is less than acceptable limit(90%). Please add more tests to improve the coverage\n"
      exit(1)
    end
  end
end
