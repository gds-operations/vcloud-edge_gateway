require 'spec_helper'
require_relative './common_differ_test_cases'

module Vcloud
  module EdgeGateway
    describe LoadBalancerConfigurationDiffer do

      specific_test_cases = [

        {
          title: 'should ignore remote config having additional :Operational keys in :Pool entries',
          src:    { Pool: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { Pool: [
            { foo: 'bar', Operational: 'wibble', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', Operational: 'wobble', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          output: []
        },

        {
          title: 'should ignore remote config having additional :Operational keys in :Pool entries, yet still report other differences ',
          src:    { Pool: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { Pool: [
            { foo: 'bar', Operational: 'wibble', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', Operational: 'wobble', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [
            ["+", "Pool[1].deeper[0]", 6],
            ["-", "Pool[1].deeper[2]", 6]
          ]
        },

      ]

      context "Common differ tests" do
        COMMON_DIFFER_TEST_CASES.each do |test_case|
          it "#{test_case[:title]}" do
            differ = LoadBalancerConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

      context "Specific LoadBalancerConfigurationDiffer tests" do
        specific_test_cases.each do |test_case|
          it "#{test_case[:title]}" do
            differ = LoadBalancerConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

    end
  end
end
