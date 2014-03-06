require 'spec_helper'
require_relative './common_differ_test_cases'

module Vcloud
  module EdgeGateway
    describe NatConfigurationDiffer do

      specific_test_cases = [

        {
          title: 'should ignore Id parameters in NatRule sections, when showing additions',
          src:    { NatRule: [
            { Id: '65539', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '65540', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { NatRule: [
            { Id: '65539', deeper: [ 1, 1, 1, 1, 1 ] },
            { Id: '65540', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '65541', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          output: [
            ["+", "NatRule[0]", {:deeper=>[1, 1, 1, 1, 1]}]
          ]
        },

        {
          title: 'should still highlight a reordering despite ignoring Id',
          src:    { NatRule: [
            { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] },
            { Id: '65539', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '65540', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { NatRule: [
            { Id: '65538', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '65539', deeper: [ 5, 6, 4, 3, 2 ] },
            { Id: '65540', deeper: [ 1, 1, 1, 1, 1 ] },
          ]},
          output: [
            ["-", "NatRule[0]", {:deeper=>[1, 1, 1, 1, 1]}],
            ["+", "NatRule[2]", {:deeper=>[1, 1, 1, 1, 1]}],
          ]
        },

        {
          title: 'should not ignore Id parameter outside of a NatRule (just in case)',
          src:    {
            NatRule: [ { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] } ],
            Id: 'outside of NAT rule'
          },
          dest:   {
            NatRule: [ { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] } ],
          },
          output: [
            ["-", "Id", 'outside of NAT rule']
          ]
        },

      ]

      context "Common differ tests" do
        COMMON_DIFFER_TEST_CASES.each do |test_case|
          it "#{test_case[:title]}" do
            differ = NatConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

      context "Specific NatConfigurationDiffer tests" do
        specific_test_cases.each do |test_case|
          it "#{test_case[:title]}" do
            differ = NatConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

    end
  end
end
