require 'securerandom'
require 'yaml'
require File.expand_path('../../data_creation', __FILE__)

begin
  @create_parms = YAML.load_file("setup.yml")['osc']
rescue
  @create_parms = YAML.load_file("setup.yml.example")['osc']
end

@time_identifier = Time.now.to_i
@user_names = []
@client_names = []
@node_names = []
@role_names = []
@data_bag_names = []
num_users = @create_parms["users"]["count"]
num_admin_users = @create_parms["users"]["admins"]
num_clients = @create_parms["clients"]["count"]
num_admin_clients = @create_parms["clients"]["admins"]
num_validator_clients = @create_parms["clients"]["validators"]
num_nodes = @create_parms["nodes"]["count"]
num_roles = @create_parms["roles"]["count"]
num_data_bags = @create_parms["data_bags"]["count"]
items_per_bag = @create_parms["data_bags"]["items_per_bag"]
keys_per_bag = @create_parms["data_bags"]["keys_per_bag"]

# create users
puts "CREATING REGULAR USERS"
(num_users - (num_users - num_admin_users)).times do |x|
  # Not impossible that we'll see periodic duplicates here,
  # just rather unlikely.
  create_user("user-#{@time_identifier}-#{SecureRandom.hex(4)}", false)
end

# create admins
puts "CREATING ADMIN USERS"
num_admin_users.times do |x|
  create_user("user-#{@time_identifier}-#{SecureRandom.hex(4)}", true)
end

# create clients
puts "CREATING REGULAR CLIENTS"
(num_clients - (num_clients - num_admin_clients - num_validator_clients)).times do |x|
  create_client("client-#{@time_identifier}-#{SecureRandom.hex(4)}", false, false)
end

# create admins
puts "CREATING ADMIN CLIENTS"
num_admin_clients.times do |x|
  create_client("client-#{@time_identifier}-#{SecureRandom.hex(4)}", true, false)
end

# create validators
puts "CREATING VALIDATOR CLIENTS"
num_validator_clients.times do |x|
  create_client("client-#{@time_identifier}-#{SecureRandom.hex(4)}", false, true)
end

# create nodes
puts "CREATING NODES"
num_nodes.times do |x|
  create_node("node-#{@time_identifier}-#{SecureRandom.hex(4)}", "")
end

# create roles
puts "CREATING ROLES"
num_roles.times do |x|
  create_role("role-#{@time_identifier}-#{SecureRandom.hex(4)}")
end

# create data bags
puts "CREATING DATA BAGS"
num_data_bags.times do |x|
  create_data_bag("data-bag-#{@time_identifier}-#{SecureRandom.hex(4)}", items_per_bag, keys_per_bag)
end

##################################################################################
BEGIN {
  def create_user(name, admin)
    puts "...creating user #{name}"
    user = api.post("users",  { "name" => name, "admin" => admin, "password" => "password"})
    File.open("testdata/keys/#{name}.pem", "w") { |f| f.write(user['private_key']) }
    @user_names << name
  end

  def create_client(name, admin, validator)
    puts "...creating client #{name}"
    client = api.post("clients",  { "name" => name, "admin" => admin, "validator" => validator})
    File.open("testdata/keys/#{name}.pem", "w") { |f| f.write(client['private_key']) }
    @client_names << name
  end

  def create_role(name)
    puts "...creating role #{name}"
    run_list = ["recipe[unicorn]", "recipe[apache2]"]
    api.post("roles",  { "name" => name, "default_attributes" => {},  "description" => "A role",  "override_attributes" => {}, "run_list" => run_list})
    @role_names << name
  end

  def create_data_bag(name, items_per_bag, keys_per_bag)
    puts "...creating data bag #{name}"
    items_per_bag.times do |x|
      "data-bag-item-#{@time_identifier}-#{SecureRandom.hex(4)}"
    end
    api.post("data",  { "name" => name })
    @data_bag_names << name

    items_per_bag.times do |y|
      item_name = "data-bag-item-#{@time_identifier}-#{SecureRandom.hex(4)}"
      payload = {"id" => item_name}

      keys_per_bag.times do |z|
        payload["key#{z}"] = "value#{z}"
      end
      api.post("data/#{name}", payload)
    end
  end

}
