#!/bin/bash
set -e

FILES=testdata/admin-config/*.rb
for f in $FILES
do
  echo "Running benchmark for org admin config $f..."
  sudo /opt/opscode/embedded/bin/knife exec "scripts/ec/benchmark/solr.rb" -c $f
done

