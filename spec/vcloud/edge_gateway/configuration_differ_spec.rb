require 'spec_helper'
require_relative './common_differ_test_cases'

module Vcloud
  module EdgeGateway
    describe ConfigurationDiffer do

      COMMON_DIFFER_TEST_CASES.each do |test_case|
        it "#{test_case[:title]}" do
          differ = ConfigurationDiffer.new(test_case[:src], test_case[:dest])
          expect(differ.diff).to eq(test_case[:output])
        end
      end

    end
  end
end
