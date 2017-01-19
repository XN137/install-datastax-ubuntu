#!/usr/bin/env bash

echo "Running install-datastax/bin/opscenter.sh"

cloud_type=$1
seed_nodes_dns_names=$2
opscenter_dns_name=$3
TOOLS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Assuming only one seed is passed in for now
seed_node_dns_name=$seed_nodes_dns_names

opscenter_ip=""
while [ "${opscenter_ip}" == "" ]; do
  opscenter_ip=`getent hosts $opscenter_dns_name | awk '{ print $1 }'`
done  
seed_node_ip=""
while [ "${seed_node_ip}" == "" ]; do
  seed_node_ip=`getent hosts $seed_node_dns_name | awk '{ print $1w }'`
done  

echo "Configuring OpsCenter with the settings:"
echo cloud_type \'$cloud_type\'
echo seed_node_ip \'$seed_node_ip\'
echo opscenter_ip \'$opscenter_ip\'

$TOOLS_DIR/opscenter/install.sh $cloud_type

echo "Starting OpsCenter..."
$TOOLS_DIR/opscenter/start.sh

echo "Waiting for OpsCenter to start..."
sleep 60

echo "Connecting OpsCenter to the cluster..."
$TOOLS_DIR/opscenter/manage_existing_cluster.sh $seed_node_ip

echo "Changing the keyspace from SimpleStrategy to NetworkTopologyStrategy."
$TOOLS_DIR/opscenter/configure_opscenter_keyspace.sh

echo "Starting DataStax Studio"
$TOOLS_DIR/opscenter/start_datastax_studio.sh $cloud_type $opscenter_ip

# Need the following while loop to run indefinitely in foreground to keep the Mesosphere task running
while true
do
  sleep 1
done
