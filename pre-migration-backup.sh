#!/bin/bash

mkdir -p testdata/pre-migration

# install the proper version of knife-ec-backup
sudo /opt/opscode/embedded/bin/rake install_deps

sudo BUNDLE_GEMFILE=./Gemfile_ruby_1 PATH=/opt/opscode/embedded/bin /bin/bash -c 'bundle exec knife ec backup testdata/pre-migration -c .chef/knife-in-guest.rb'

