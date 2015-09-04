require 'securerandom'
require 'yaml'
require File.expand_path('../../data_creation', __FILE__)

begin
  @create_parms = YAML.load_file("setup.yml")["ec"]
rescue
  @create_parms = YAML.load_file("setup.yml.example")["ec"]
end

org = Chef::Config['chef_server_url'].split("/")[-1]
created_objects = YAML.load_file("testdata/created-objects.yml")

@time_identifier = Time.now.to_i
nodes_per_org = @create_parms["orgs"]["per_org"]["nodes"]
roles_per_org = @create_parms["orgs"]["per_org"]["roles"]

num_data_bags = @create_parms["orgs"]["per_org"]["data_bags"]["count"]
items_per_bag = @create_parms["orgs"]["per_org"]["data_bags"]["items_per_bag"]
keys_per_bag = @create_parms["orgs"]["per_org"]["data_bags"]["keys_per_bag"]

created_objects['orgs'][org]['nodes'] = []
nodes_per_org.times do
  node = "node-#{@time_identifier}-#{SecureRandom.hex(4)}"
  created_objects['orgs'][org]['nodes'] << node
  create_node(node, Chef::Config['chef_server_url'])
end

roles_per_org.times do
  create_role("role-#{@time_identifier}-#{SecureRandom.hex(4)}", Chef::Config['chef_server_url'])
end

num_data_bags.times do |x|
  create_data_bag("data-bag-#{@time_identifier}-#{SecureRandom.hex(4)}", items_per_bag, keys_per_bag, @time_identifier, Chef::Config['chef_server_url'])
end

File.open("testdata/created-objects.yml", "w") do |f|
  YAML.dump(created_objects, f)
end

# TODO add nodes, roles, data bags, and items to testdata/created-objects.yml
