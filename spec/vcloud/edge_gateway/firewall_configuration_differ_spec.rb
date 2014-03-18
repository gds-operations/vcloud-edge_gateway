require 'spec_helper'
require_relative 'configuration_differ_shared_examples.rb'

module Vcloud
  module EdgeGateway
    describe FirewallConfigurationDiffer do

      it_behaves_like "a configuration differ" do
        let(:config_differ) { FirewallConfigurationDiffer }
      end

      it 'should ignore Id parameters in FirewallRule sections, when showing additions' do
        local = { FirewallRule: [
            { Id: '1', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '2', deeper: [ 5, 6, 4, 3, 2 ] },
          ]}
        remote = { FirewallRule: [
            { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] },
            { Id: '2', deeper: [ 1, 2, 3, 4, 5 ] },
            { Id: '3', deeper: [ 5, 6, 4, 3, 2 ] },
          ]}
        output = [
            ["+", "FirewallRule[0]", {:deeper=>[1, 1, 1, 1, 1]}]
          ]
        differ = FirewallConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should still highlight a reordering despite ignoring Id' do
        local = { FirewallRule: [
          { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] },
          { Id: '2', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '3', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { FirewallRule: [
          { Id: '1', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '2', deeper: [ 5, 6, 4, 3, 2 ] },
          { Id: '3', deeper: [ 1, 1, 1, 1, 1 ] },
        ]}
        output = [
          ["-", "FirewallRule[0]", {:deeper=>[1, 1, 1, 1, 1]}],
          ["+", "FirewallRule[2]", {:deeper=>[1, 1, 1, 1, 1]}],
        ]
        differ = FirewallConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should not ignore Id parameter outside of a FirewallRule (just in case)' do
        local = {
         FirewallRule: [ { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] } ],
         Id: 'outside of firewall rule'
        }
        remote = {
         FirewallRule: [ { Id: '1', deeper: [ 1, 1, 1, 1, 1 ] } ],
        }
        output = [
         ["-", "Id", 'outside of firewall rule']
        ]
        differ = FirewallConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

    end
  end
end
