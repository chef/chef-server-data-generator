#require 'securerandom'

def create_node(name, base_url)
  puts "...creating node #{name}"
  attributes = {}
  rand(10 - 0).times do |x|
    attributes["key-#{x}"] = "value-#{x}"
  end
  api.post("#{base_url}/nodes", {"name" => name, "chef_environment" => "_default", "normal" => attributes, "automatic" => {}, "override" => {}, "default" => {}, "run_list" => []})
end
