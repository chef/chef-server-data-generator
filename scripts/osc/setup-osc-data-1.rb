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
  create_role("role-#{@time_identifier}-#{SecureRandom.hex(4)}", "")
end

# create data bags
puts "CREATING DATA BAGS"
num_data_bags.times do |x|
  create_data_bag("data-bag-#{@time_identifier}-#{SecureRandom.hex(4)}", items_per_bag, keys_per_bag, @time_identifier, "")
end

### TESTCASE DATA ###
if @create_parms["test_case_data"]
  # POOL-607 - client & nodes with '.' in the name
  slug = SecureRandom.hex(4)
  name_607 = "pool-607.#{@time_identifier}-#{slug}"
  create_client(name_607)
  create_node(name_607)
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

}
