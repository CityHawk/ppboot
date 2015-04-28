#!/usr/bin/env bash

set -e

rubies=("ruby-2.0.0" "ruby-1.9.3" "jruby-1.6.7.2" "jruby-1.7.3")
for i in "${rubies[@]}"
do
  echo "====================================================="
  echo "$i: Start Test"
  echo "====================================================="
  rvm $i exec bundle install
  rvm $i exec appraisal install
  rvm $i exec appraisal rake spec
  echo "====================================================="
  echo "$i: End Test"
  echo "====================================================="
done

