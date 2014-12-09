#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
for n in "$@"
do
  apt-get -y --force-yes install $n
done
