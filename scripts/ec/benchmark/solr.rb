require 'yaml'
require 'json'
require 'thread'
require 'logger'

THREAD_COUNT=4
TOTAL_WRITES=1000


#
# Logger is used to print to stdout since `puts` isn't thread-safe by
# default.
#
logger = Logger.new(STDOUT)
logger.formatter = proc {|severity, datetime, progname, msg| msg + "\n" }

#
# Takes and returns an integer with how many writes
# each thread should do.  For now, if TOTAL/WRITES isnt'
# evenly divisible by the thread count, we put the remainder on the last one.
#
def writes_for_thread(thread_number)
  @writes_per_thread ||= begin
                           div = TOTAL_WRITES / THREAD_COUNT
                           rem = TOTAL_WRITES % THREAD_COUNT
                           ([div] * (THREAD_COUNT - 1)) + [div+rem]
                         end
  @writes_per_thread[thread_number-1]
end

created_objects = YAML.load_file("testdata/created-objects.yml")
ohai_data = JSON.parse(File.read("testdata/ohaidata.json"))

logger.info("Retrieving node objects from server")
org = Chef::Config['chef_server_url'].split("/")[-1]
nodes = created_objects["orgs"][org]["nodes"]
node_objects = nodes.map do |n|
  o = api.get("/nodes/#{n}")
  o.automatic_attrs = ohai_data
  o
end

threads = []
start_time = Time.now

Thread.abort_on_exception = true
1.upto(THREAD_COUNT).each do |i|
  threads << Thread.new(writes_for_thread(i)) do |count|
    logger.info "Starting worker thread #{i}"
    1.upto(count).each do
      node_object = node_objects.sample
      # Ensure that the node data changes
      node_object.default_attrs = {"test_attr" => "#{rand(10000)}-#{rand(10000)}"}
      node_object.save
    end
  end
end

threads.each {|t| t.join}
total_time = (Time.now - start_time) * 1000.0 # Time in ms
logger.info "Wrote #{TOTAL_WRITES} times in #{total_time} ms using #{THREAD_COUNT} workers"
exit 0
