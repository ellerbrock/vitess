#!/bin/bash

# This is an example script that creates etcd clusters.
# Vitess requires a global cluster, as well as one for each cell.
#
# For automatic discovery, an etcd cluster can be bootstrapped from an
# existing cluster. In this example, we use an externally-run discovery
# service, but you can use your own. See the etcd docs for more:
# https://github.com/coreos/etcd/blob/v0.4.6/Documentation/cluster-discovery.md

set -e

script_root=`dirname "${BASH_SOURCE}"`
source $script_root/env.sh

replicas=${ETCD_REPLICAS:-3}

for cell in 'global' 'test'; do
  # Generate a discovery token.
  echo "Generating discovery token for $cell cell..."
  discovery=$(curl -sL https://discovery.etcd.io/new?size=$replicas)

  # Create the client service, which will load-balance across all replicas.
  echo "Creating etcd service for $cell cell..."
  cat etcd-service-template.yaml | \
    sed -e "s/{{cell}}/$cell/g" | \
    $KUBECTL create -f -

  # Expand template variables
  sed_script=""
  for var in cell discovery replicas; do
    sed_script+="s,{{$var}},${!var},g;"
  done

  # Create the replication controller.
  echo "Creating etcd replicationcontroller for $cell cell..."
  cat etcd-controller-template.yaml | sed -e "$sed_script" | $KUBECTL create -f -
done

