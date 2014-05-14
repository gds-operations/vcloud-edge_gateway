require 'spec_helper'

module Vcloud
  describe "load balancer service schema validation" do

    context "validate pool entry" do

      valid_tests = [
        {
          name: 'should validate ok if only mandatory fields are provided',
          input: {
            name: 'pool entry 1',
            members: [
              { ip_address: "192.2.0.40" },
              { ip_address: "192.2.0.41" },
            ]
          }
        },
        {
          name: 'should validate a complete pool specification',
          input: {
            name: 'pool entry 1',
            description: 'description of pool entry 1',
            service: {
              http: {
                enabled: true,
                port: 8080,
                algorithm: 'ROUND_ROBIN',
                health_check: {
                  port: 80,
                  protocol: 'HTTP',
                  health_threshold: 4,
                  unhealth_threshold: 10,
                  interval: 10,
                  timeout: 5,
                },
              },
            },
            members: [
              { ip_address: "192.2.0.40",
                weight: 2,
                service_port: {
                  http: {
                    port: 8080,
                    health_check_port: 8080,
                  }
                }
              },
            ]
          }
        },
      ]

      valid_tests.each do |test|
        it "#{test[:name]}" do
          validator = Vcloud::Core::ConfigValidator.validate(:base, test[:input],
              Vcloud::EdgeGateway::Schema::LOAD_BALANCER_POOL_ENTRY)
          expect(validator.errors).to eq([])
          expect(validator.valid?).to be_true
        end
      end

    end

    context "validate virtual_server entry" do

      valid_tests = [
        {
          name: 'should validate ok if only mandatory fields are provided',
          input: {
            name: 'virtual_server entry 1',
            ip_address: "192.2.0.40",
            network: "TestNetwork",
            pool: "TestPool",
          }
        },
        {
          name: 'should validate a complete virtual_server specification',
          input: {
            name: 'virtual_server entry 1',
            ip_address: "192.2.0.40",
            network: "TestNetwork",
            pool: "TestPool",
            logging: true,
            service_profiles: {
              http: { enabled: true, port: 8080 },
              https: { enabled: false, port: 8443 },
              tcp: { enabled: false },
            },
          }
        },
      ]

      valid_tests.each do |test|
        it "#{test[:name]}" do
          validator = Vcloud::Core::ConfigValidator.validate(:base, test[:input],
              Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
          expect(validator.errors).to eq([])
          expect(validator.valid?).to be_true
        end
      end

      it "validates a virtual_server entry with a COOKIE http persistence method" do
        input = {
          name: 'virtual server with COOKIE persistence',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
          logging: true,
          service_profiles: {
             http: {
               enabled: true,
               port: 8080,
               persistence: {
                 method: 'COOKIE',
                 cookie_name: 'JSESSIONID',
                 cookie_mode: 'APP',
               },
             },
          }
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input,
          Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "does not validate a virtual_server entry with a COOKIE http " +
           "persistence method, when no cookie_name or cookie_mode is specified" do
        input = {
          name: 'virtual server with COOKIE persistence',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
          logging: true,
          service_profiles: {
             http: {
               enabled: true,
               port: 8080,
               persistence: {
                 method: 'COOKIE',
               },
             },
          }
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input,
          Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq([
          "persistence: missing 'cookie_name' parameter",
          "persistence: missing 'cookie_mode' parameter",
        ])
        expect(validator.valid?).to be_false
      end

      it "validates a virtual_server entry with a SSL_SESSION_ID https persistence method" do
        input = {
          name: 'virtual server with SSL_SESSION_ID persistence',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
          logging: true,
          service_profiles: {
             https: {
               enabled: true,
               port: 8080,
               persistence: {
                 method: 'SSL_SESSION_ID',
               },
             },
          }
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input,
          Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "validates a virtual_server entry with a tcp service_profile" do
        input = {
          name: 'virtual server with tcp service_profile',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
          logging: true,
          service_profiles: {
             tcp: {
               enabled: true,
               port: 7777,
             },
          }
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input,
          Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "does not validate a virtual_server tcp service_profile with a persistence section" do
        input = {
          name: 'BOGUS virtual server with tcp service profile persistence section',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
          logging: true,
          service_profiles: {
             tcp: {
               enabled: true,
               port: 7777,
               persistence: {},
             },
          }
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input,
          Vcloud::EdgeGateway::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq(["tcp: parameter 'persistence' is invalid"])
        expect(validator.valid?).to be_false
      end

    end

    context "check complete load balancer sections" do

      it "validate ok if only mandatory fields are provided" do
        input = {
          pools: [
            {
              name: 'pool entry 1',
              members: [
                { ip_address: "192.2.0.40" },
                { ip_address: "192.2.0.41" },
              ]
            },
          ],
          virtual_servers: [
            {
              name: 'virtual_server entry 1',
              ip_address: "192.2.0.40",
              network: "TestNetwork",
              pool: "TestPool",
            },
          ],
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input, Vcloud::EdgeGateway::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "should validate ok if an empty pool service section is provided" do
        input = {
          pools: [
            {
              name: 'pool entry 1',
              service: {
                http: {},
              },
              members: [
                { ip_address: "192.2.0.40" },
                { ip_address: "192.2.0.41" },
              ]
            },
          ],
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input, Vcloud::EdgeGateway::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "should validate ok if an empty virtual_server service_profile section is provided" do
        input = {
          pools: [{
            name: 'pool-1',
            service: { http: {} },
            members: [ { ip_address: '10.10.10.10' } ],
          }],
          virtual_servers: [
            {
              name: 'virtual_server entry 1',
              ip_address: "192.2.0.40",
              network: "TestNetwork",
              service_profiles: { http: {} },
              pool: "pool-1",
            },
          ],
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input, Vcloud::EdgeGateway::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "should be ok if no pools are specified" do
        input = {
          virtual_servers: []
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input, Vcloud::EdgeGateway::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.valid?).to be_true
      end

      it "should be ok if no virtual_servers are specified" do
        input = {
          pools: []
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, input, Vcloud::EdgeGateway::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.valid?).to be_true
      end

    end

  end
end
