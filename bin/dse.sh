#!/usr/bin/env bash

echo "Running install-datastax/bin/dse.sh"

cloud_type=$1
seed_nodes_dns_names=$2
data_center_name=$3

# Assuming only one seed is passed in for now
seed_node_dns_name=$seed_nodes_dns_names

# On AWS and Azure this gets the public IP.  On Google it resolves to a private IP that is globally routeable in GCP.
seed_node_ip=`dig +short $seed_node_dns_name`

if [[ $cloud_type == "google" ]]; then
  # On Google private IPs are globally routable within GCP
  # We've also been seeing issues using the public ones for broadcast.
  # So, we're just going to use the private for everything.
  node_broadcast_ip=`echo $(hostname -I)`
  node_ip=`echo $(hostname -I)`
else
  node_broadcast_ip=`curl --retry 10 icanhazip.com`
  node_ip=`echo $(hostname -I)`
fi

echo "Configuring nodes with the settings:"
echo cloud_type \'$cloud_type\'
echo data_center_name \'$data_center_name\'
echo seed_node_ip \'$seed_node_ip\'
echo node_broadcast_ip \'$node_broadcast_ip\'
echo node_ip \'$node_ip\'

#### Ok, now let's starting making changes to the system...

./os/install_java.sh

if [[ $cloud_type == "azure" ]]; then
  ./os/set_tcp_keepalive_time.sh
fi

./dse/install.sh
./dse/configure_cassandra_rackdc_properties.sh $cloud_type $data_center_name
./dse/configure_cassandra_yaml.sh $node_ip $node_broadcast_ip $seed_node_ip
./dse/configure_agent_address_yaml.sh $node_ip $node_broadcast_ip
./dse/start.sh
