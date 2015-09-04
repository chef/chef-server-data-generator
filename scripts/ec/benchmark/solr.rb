require 'yaml'
created_objects = YAML.load_file("testdata/created-objects.yml")

org = Chef::Config['chef_server_url'].split("/")[-1]
nodes = created_objects["orgs"][org]["nodes"]

nodes.each do |node|
  node_object = api.get("/nodes/#{node}")
  node_object.default_attrs = {"test_attr" => "test_value"}
  node_object.save
end

