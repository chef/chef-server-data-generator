#!/bin/bash

mkdir -p testdata/pre-migration

# install the proper version of knife-ec-backup
/opt/opscode/embedded/bin/rake install_deps

sudo /opt/opscode/embedded/bin/knife ec backup testdata/pre-migration -c .chef/knife-in-guest.rb
