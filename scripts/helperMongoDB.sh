#!/bin/bash

action=${1:-install}
mongoUser="$2"
mongoPassword="$3"
echo "Info: action=$action";

now=$(date +%s)
    
case $action in
uninstall)
    if [ -f /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml ]; then
        mv /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml.$now;
    fi
;;
    install)

    if [ -f /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml ]; then
        mv /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml.$now;
    fi
    touch /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml
    chown solarwinds.solarwinds /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml
    cat <<EOF > /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml
collector:
  mongodb:
    all:
      # uri specifies IP and port on which to connect with MongoDb instance
      uri: "localhost:27017"
      # if 'security.authorization' is enabled this field should contain valid username created within MongoDb (with clusterMonitor or admin role). Otherwise it should remain empty.
      username: "$mongoUser"
      # if 'security.authorization' is enabled this field should contain valid password associated with username. Otherwise it should remain empty.
      password: "$mongoPassword"

load:
  plugin: snap-plugin-collector-aomongodb
  task: task-aomongodb.yaml
EOF
    diff /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml /opt/SolarWinds/Snap/etc/plugins.d/mongodb.yaml.$now
;;
esac
    jem service restart swisnapd
