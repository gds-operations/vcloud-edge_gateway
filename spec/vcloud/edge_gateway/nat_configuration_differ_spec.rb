require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe NatConfigurationDiffer do

      it 'should ignore Id parameters in NatRule sections, when showing additions' do
        local = { NatRule: [
          { Id: '65539', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '65540', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { NatRule: [
          { Id: '65539', deeper: [ 1, 1, 1, 1, 1 ] },
          { Id: '65540', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '65541', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        output = [
          ["+", "NatRule[0]", {:deeper=>[1, 1, 1, 1, 1]}]
        ]
        differ = NatConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should still highlight a reordering despite ignoring Id' do
        local = { NatRule: [
          { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] },
          { Id: '65539', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '65540', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { NatRule: [
          { Id: '65538', deeper: [ 1, 2, 3, 4, 5 ] },
          { Id: '65539', deeper: [ 5, 6, 4, 3, 2 ] },
          { Id: '65540', deeper: [ 1, 1, 1, 1, 1 ] },
        ]}
        output = [
          ["-", "NatRule[0]", {:deeper=>[1, 1, 1, 1, 1]}],
          ["+", "NatRule[2]", {:deeper=>[1, 1, 1, 1, 1]}],
        ]
        differ = NatConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should not ignore Id parameter outside of a NatRule (just in case)' do
        local = {
          NatRule: [ { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] } ],
          Id: 'outside of NAT rule'
        }
        remote = {
          NatRule: [ { Id: '65538', deeper: [ 1, 1, 1, 1, 1 ] } ],
        }
        output =  [
          ["-", "Id", 'outside of NAT rule']
        ]
        differ = NatConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

    end
  end
end
