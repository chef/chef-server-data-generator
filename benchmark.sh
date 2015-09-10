#!/bin/bash
set -e

# generate OHAI data
sudo /opt/opscode/embedded/bin/ohai > testdata/ohaidata.json

# generate per org data (iterate over org admin configs)
FILES=testdata/admin-config/*.rb
for f in $FILES
do
  echo "Running benchmark for org admin config $f..."
  sudo /opt/opscode/embedded/bin/knife exec "scripts/ec/benchmark/solr.rb" -c $f
done

