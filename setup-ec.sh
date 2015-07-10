#!/bin/bash

mkdir -p testdata/keys
# Create some data
sudo /opt/opscode/embedded/bin/knife exec "scripts/ec/setup-data-1.rb" -c .chef/knife-in-guest.rb
# Test uploading the cron cookbook
sudo /opt/opscode/embedded/bin/knife cookbook upload cron -c .chef/knife-in-guest.rb
