require 'spec_helper'

describe Vcloud::EdgeGateway::Configure do
  describe 'dry_run' do
    let(:expected_log_message) {
      /: Dry run\. Skipping\.$/
    }
    let(:mock_edgegateway) {
      double(:edgegateway,
        :interfaces => 'chocolate cake',
        :vcloud_attributes => {
          :Configuration => {
            :EdgeGatewayServiceConfiguration => 'ice cream cone',
          }
        }
      )
    }

    before(:each) {
      Vcloud::Core::EdgeGateway.stub(:get_by_name).and_return(mock_edgegateway)

      mock_configloader = double(:configloader,
        :load_config => { :gateway => 'pickle' }
      )
      Vcloud::Core::ConfigLoader.stub(:new).and_return(mock_configloader)

      mock_configuration = double(:configuration,
        :update_required? => true,
        :config => 'slice of swiss cheese',
        :diff => ['slice of salami'],
      )
      Vcloud::EdgeGateway::EdgeGatewayConfiguration.stub(:new).and_return(mock_configuration)
    }

    context "when false (default)" do
      let(:subject) {
        Vcloud::EdgeGateway::Configure.new('lollipop.yaml').update
      }

      it "should call update_configuration" do
        expect(mock_edgegateway).to receive(:update_configuration).with('slice of swiss cheese')
        subject
      end

      it "should not log message about dry run" do
        mock_edgegateway.stub(:update_configuration)
        expect(Vcloud::Core.logger).not_to receive(:info).with(expected_log_message)
        subject
      end

      it "should return diff" do
        mock_edgegateway.stub(:update_configuration)
        expect(subject).to eq(['slice of salami'])
      end
    end

    context "when true" do
      let(:subject) {
        Vcloud::EdgeGateway::Configure.new('lollipop.yaml').update(true)
      }

      it "should not call update_configuration" do
        Vcloud::Core.logger.stub(:info)
        expect(mock_edgegateway).not_to receive(:update_configuration)
        subject
      end

      it "should log message about dry run" do
        mock_edgegateway.stub(:update_configuration)
        expect(Vcloud::Core.logger).to receive(:info).with(expected_log_message)
        subject
      end

      it "should return diff" do
        Vcloud::Core.logger.stub(:info)
        mock_edgegateway.stub(:update_configuration)
        expect(subject).to eq(['slice of salami'])
      end
    end
  end
end
