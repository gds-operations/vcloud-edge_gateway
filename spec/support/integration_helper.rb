module IntegrationHelper
  def self.fixture_path
    File.expand_path("../integration/edge_gateway/data", File.dirname(__FILE__))
  end

  def self.fixture_file(path)
    File.join(self.fixture_path, path)
  end

  def self.remove_temp_config_files(files_to_delete)
    files_to_delete.each { |f|
      f.unlink
    }
  end

  def self.get_last_task(gateway_name)
    tasks = Vcloud::Core::QueryRunner.new.run('task',
      :filter   => "name==networkConfigureEdgeGatewayServices;" + \
                   "objectName==#{gateway_name}",
      :sortDesc => 'startDate',
      :pageSize => 1,
    )

    raise "Unable to find last vCloud task" if tasks.empty?
    tasks.first
  end

  def self.get_tasks_since(gateway_name, task)
    tasks = Vcloud::Core::QueryRunner.new.run('task',
      :filter   => "name==networkConfigureEdgeGatewayServices;" + \
                   "objectName==#{gateway_name};" + \
                   "startDate=ge=#{task.fetch(:startDate)}",
      :sortDesc => 'startDate',
    )

    tasks.reject! { |t| t.fetch(:href) == task.fetch(:href) }
    tasks
  end
end
