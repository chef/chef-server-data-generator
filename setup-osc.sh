#!/bin/bash

mkdir -p testdata/keys
# Create some data
sudo /opt/chef-server/embedded/bin/knife exec "scripts/osc/setup-osc-data-1.rb" -c .chef/knife-in-guest.rb -VV
# Test uploading the cron cookbook
sudo /opt/chef-server/embedded/bin/knife cookbook upload cron -c .chef/knife-in-guest.rb
