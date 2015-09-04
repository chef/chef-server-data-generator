require 'securerandom'
require 'yaml'

org = Chef::Config['chef_server_url'].split("/")[-1]
created_objects = YAML.load_file("testdata/created-objects.yml")

puts "wtf"
puts org
puts created_objects['orgs'][org]

created_objects['orgs'][org]['nodes'] = []
nodes_per_org.times do
  node = "node-#{@time_identifier}-#{SecureRandom.hex(4)}"
  created_objects['orgs'][org]['nodes'] << node
end

File.open("testdata/created-objects.yml", "w") do |f|
  YAML.dump(created_objects, f)
end
