module IntegrationHelper
  def self.fixture_path
    File.expand_path("../integration/edge_gateway/data", File.dirname(__FILE__))
  end

  def self.fixture_file(path)
    File.join(self.fixture_path, path)
  end
end
