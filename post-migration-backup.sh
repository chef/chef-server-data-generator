#!/bin/bash

mkdir -p testdata/post-migration


# re-install knife-ec-backup since ruby might be on 2.0 post-upgrade
/opt/opscode/embedded/bin/rake install_deps

sudo /opt/opscode/embedded/bin/knife ec backup testdata/post-migration -c .chef/knife-in-guest.rb
