#!/bin/sh
set -x
env ASSUME_ALWAYS_YES=yes pkg
env ASSUME_ALWAYS_YES=yes pkg install -y --ignore-missing `cat $1 | xargs`
