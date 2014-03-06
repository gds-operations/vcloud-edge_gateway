require 'spec_helper'
require_relative './common_differ_test_cases'

module Vcloud
  module EdgeGateway
    describe FirewallConfigurationDiffer do

      specific_test_cases = [

        {
          title: 'should ignore Id parameters in FirewallRule sections, when showing additions',
          src:    { FirewallRule: [
            { Id: '1', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '2', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { FirewallRule: [
            { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] },
            { Id: '2', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '3', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          output: [
            ["+", "FirewallRule[0]", {:deeper=>[1, 1, 1, 1, 1]}]
          ]
        },

        {
          title: 'should still highlight a reordering despite ignoring Id',
          src:    { FirewallRule: [
            { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] },
            { Id: '2', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '3', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { FirewallRule: [
            { Id: '1', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '2', deeper: [ 5, 6, 4, 3, 2 ] },
            { Id: '3', deeper: [ 1, 1, 1, 1, 1 ] },
          ]},
          output: [
            ["-", "FirewallRule[0]", {:deeper=>[1, 1, 1, 1, 1]}],
            ["+", "FirewallRule[2]", {:deeper=>[1, 1, 1, 1, 1]}],
          ]
        },

        {
          title: 'should not ignore Id parameter outside of a FirewallRule (just in case)',
          src:    {
            FirewallRule: [ { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] } ],
            Id: 'outside of firewall rule'
          },
          dest:   {
            FirewallRule: [ { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] } ],
          },
          output: [
            ["-", "Id", 'outside of firewall rule']
          ]
        },

      ]

      context "Common differ tests" do
        COMMON_DIFFER_TEST_CASES.each do |test_case|
          it "#{test_case[:title]}" do
            differ = FirewallConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

      context "Specific FirewallConfigurationDiffer tests" do
        specific_test_cases.each do |test_case|
          it "#{test_case[:title]}" do
            differ = FirewallConfigurationDiffer.new(test_case[:src], test_case[:dest])
            expect(differ.diff).to eq(test_case[:output])
          end
        end
      end

    end
  end
end
