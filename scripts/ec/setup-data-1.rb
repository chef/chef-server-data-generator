require 'securerandom'
require 'yaml'
require File.expand_path('../../data_creation', __FILE__)

begin
  @create_parms = YAML.load_file("setup.yml")["ec"]
rescue
  @create_parms = YAML.load_file("setup.yml.example")["ec"]
end

@time_identifier = Time.now.to_i
@orgs = {}
@user_names = []
num_orgs = @create_parms["orgs"]["count"]
users_per_org = @create_parms["orgs"]["per_org"]["users"]
clients_per_org = @create_parms["orgs"]["per_org"]["clients"]
groups_per_org =  @create_parms["orgs"]["per_org"]["groups"]
nodes_per_org = @create_parms["orgs"]["per_org"]["nodes"]
roles_per_org = @create_parms["orgs"]["per_org"]["roles"]

num_orgs.times do
  org_users = []
  users_per_org.times do |x|
    user = "user-#{@time_identifier}-#{SecureRandom.hex(4)}"
    org_users << user
    create_user(user)
  end

  org_name = "org-#{@time_identifier}-#{SecureRandom.hex(4)}"
  create_org(org_name, org_users, org_users[0])
  clients_per_org.times { create_org_client(org_name, false) }
  org_clients = @orgs[org_name]["clients"]
  # Creates randomly named group with random membership
  groups_per_org.times { create_and_populate_org_group(org_name, org_users, org_clients ) }
  org_groups = @orgs[org_name]["groups"].keys.reject{ |k| k == "admins" || k == "users" || k == "billing-admins" }

  # Just split groups in half, take the first group in each half, and add the remaining
  # groups in the half to it.   Avoids having to track circular dependencies if we do
  # it by random assignment.
  org_groups.each_slice(groups_per_org / 2) do |member_groups|
    # don't  bother if we don't have enough groups to care about.
    next if member_groups.length < 2
    owning_group = member_groups.shift
    add_to_group(org_name, owning_group, { :groups => member_groups} )
  end

  # Sanity check:
  g = api.get("organizations/#{org_name}/groups/admins")

  puts "DEBUG: ADMIN GROUP NOW IS: #{g.inspect}"
end

all = { "orgs" => @orgs, "users" => @user_names }

# this is available as input for other steps and components.
File.open("testdata/created-objects.yml", "w") do |f|
  YAML.dump(all, f)
end

##################################################################################
BEGIN {

  def create_user(name)
    puts "...creating user #{name}"
    user = api.post("users",  { "display_name" => name, "email" => "#{name}@testing.com", "username"=> name, "password" => "password"})
    if user['private_key'].nil?
      # API V1, delete user and try again with proper request
      api.delete("users/#{name}")
      user = api.post("users",  { "display_name" => name, "email" => "#{name}@testing.com", "username"=> name, "password" => "password", "create_key" => true})
      File.open("testdata/keys/#{name}.pem", "w") { |f| f.write(user['chef_key']['private_key']) }
    else
      File.open("testdata/keys/#{name}.pem", "w") { |f| f.write(user['private_key']) }
    end
    @user_names << name
  end

  def associate_user(org_name, user_name)
    puts "...associating #{user_name} with #{org_name}"
    # old style: before 12 we can't directly associate a user with an org.
    response = api.post("organizations/#{org_name}/association_requests", { "user" => user_name } )
    id = /.*\/(.*)$/.match(response["uri"])[1]
    api.put("users/#{user_name}/association_requests/#{id}", { "response" => "accept" } )
  end

  def add_to_group(org_name, group_name, who)
    puts "...adding members to #{org_name}/groups/#{group_name}"
    who[:users] = [] if who[:users].nil?
    who[:clients] = [] if who[:clients].nil?
    who[:groups] = [] if who[:groups].nil?
    g = api.get("organizations/#{org_name}/groups/#{group_name}")
    g2 = g.dup # TODO probably dont' really need g2...
    g2["actors"] = {}
    g2["actors"]["users"] = g["users"] + who[:users]
    g2["actors"]["groups"] = g["groups"] + who[:groups]
    g2["actors"]["clients"] = g["clients"] + who[:clients]
    api.put("organizations/#{org_name}/groups/#{group_name}", g2)
    @orgs[org_name]["groups"][group_name] = {} # we're going to overwrite it with what the server just told us anyway...
    @orgs[org_name]["groups"][group_name]["users"] = g2["actors"]["users"]
    @orgs[org_name]["groups"][group_name]["clients"] = g2["actors"]["clients"]
    @orgs[org_name]["groups"][group_name]["groups"] = g2["actors"]["groups"]
  end

  def create_org_client(org_name, validator)
    client_name = "client-#{SecureRandom.hex(4)}-#{org_name}"
    puts  "... creating client #{client_name}"
    begin # API V0
      result = api.post("organizations/#{org_name}/clients", { "clientname" => client_name, "validator" => validator, "private_key" => true })
      File.open("testdata/keys/#{client_name}.pem", "w") { |f| f.write(result['private_key']) }
    rescue # API V1
      result = api.post("organizations/#{org_name}/clients", { "clientname" => client_name, "validator" => validator, "create_key" => true })
      File.open("testdata/keys/#{client_name}.pem", "w") { |f| f.write(result['chef_key']['private_key']) }
    end
    @orgs[org_name]["clients"] << client_name
  end

  def create_and_populate_org_group(org_name,orgusers,orgclients)
    group_name = "group-#{SecureRandom.hex(4)}-#{org_name}"
    puts  "... creating group #{group_name}"
    memberusers = random_elements(1, orgusers.length, orgusers)
    memberclients = random_elements(1, orgclients.length, orgclients)
    # Old style - before 12 we could not add members at time of defining group
    api.post("organizations/#{org_name}/groups", {"groupname" => group_name})
    add_to_group(org_name, group_name, {:users => memberusers, :clients => memberclients})
  end

  def create_org(name, users, admin)
    puts "...creating org #{name}"
    org = api.post("organizations", { "full_name" => "#{name}", "name" => "#{name}" })
    validator_key = "testdata/keys/#{name}-validator.pem"
    File.open(validator_key, "w") do |f|
      f.write(org['private_key'])
    end
    users.each do |user_name|
      associate_user(name, user_name)
    end
    @orgs[name] =  { "groups" => { "billing-admins" => {},  "admins" => {}, "users" => {}},
                     "clients" => ["#{name}-validator"] }
    puts "......associating admin #{admin}"
    add_to_group(name, "admins", {:users => [admin]} )
    add_to_group(name, "billing-admins", {:users => [admin]} )

    # write a knife config for each admin to perform admin specific actions
    chef_server_url = Chef::Config['chef_server_url']    
    knife = "testdata/admin-config/#{admin}.rb"
    puts "......writing admin config #{knife}"
    knife_content = <<-EOH
current_dir = File.dirname(__FILE__)
chef_server_url "#{chef_server_url}/organizations/#{name}"
node_name "#{admin}"
client_key "\#{current_dir}/../keys/#{admin}.pem"
ssl_verify_mode :verify_none
cookbook_path [ "\#{current_dir}/../../cookbooks" ]
EOH
    File.open(knife, "w") do |f|
      f.write(knife_content)
    end
  end

  def random_elements(min, max, ary)
    # Trusting you to pass in valid min/max here...
    count = rand(max - min) + min
    ary.dup.shuffle[0..count-1]
  end
}
