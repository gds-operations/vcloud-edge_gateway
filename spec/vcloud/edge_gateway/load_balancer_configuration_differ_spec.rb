require 'spec_helper'
require_relative 'configuration_differ_shared_examples.rb'

module Vcloud
  module EdgeGateway
    describe LoadBalancerConfigurationDiffer do

      it_behaves_like "a configuration differ" do
        let(:config_differ) { LoadBalancerConfigurationDiffer }
      end

      it 'should ignore remote config having additional :Operational keys in :Pool entries' do
        local = { Pool: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { Pool: [
          { foo: 'bar', Operational: 'wibble', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', Operational: 'wobble', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        output =  []
        differ = LoadBalancerConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should ignore remote config having additional :Operational keys in :Pool entries, yet still report other differences' do
        local = { Pool: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { Pool: [
          { foo: 'bar', Operational: 'wibble', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', Operational: 'wobble', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output =  [
          ["+", "Pool[1].deeper[0]", 6],
          ["-", "Pool[1].deeper[2]", 6]
        ]
        differ = LoadBalancerConfigurationDiffer.new(local, remote)
        expect(differ.diff).to eq(output)
      end

    end
  end
end
