module IntegrationHelper
  REQUIRED_ENV = {
    'VCLOUD_EDGE_GATEWAY' => 'to name of VSE',
    'VCLOUD_PROVIDER_NETWORK_ID' => 'to ID of VSE external network',
    'VCLOUD_PROVIDER_NETWORK_IP' => 'to an available IP on VSE external network',
    'VCLOUD_NETWORK1_ID' => 'to the ID of a VSE internal network',
    'VCLOUD_NETWORK1_NAME' => 'to the name of the VSE internal network',
    'VCLOUD_NETWORK1_IP' => 'to an ID on the VSE internal network',
  }

  def self.verify_env_vars
    error = false
    REQUIRED_ENV.each do |var,message|
      unless ENV[var]
        puts "Must set #{var} #{message}" unless ENV[var]
        error = true
      end
    end
    Kernel.exit(2) if error
  end

  def self.fixture_path
    File.expand_path("../integration/edge_gateway/data", File.dirname(__FILE__))
  end

  def self.fixture_file(path)
    File.join(self.fixture_path, path)
  end
end
