require 'spec_helper'
require_relative 'configuration_differ_shared_examples'

module Vcloud
  module EdgeGateway

    describe ConfigurationDiffer do
      it_behaves_like "a configuration differ" do
        let(:config_differ) { ConfigurationDiffer }
      end
    end

  end
end
