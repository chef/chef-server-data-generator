current_dir = File.dirname(__FILE__)
chef_server_url "https://192.168.33.10" 
node_name "pivotal" 
client_key "/etc/opscode/pivotal.pem" 
ssl_verify_mode :verify_none
cookbook_path [ "#{current_dir}/../cookbooks" ]

