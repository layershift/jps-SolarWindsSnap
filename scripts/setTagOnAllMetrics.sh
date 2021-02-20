#!/bin/bash

if [ "$1" == "" ]; then
    echo "Info: No tag specified. No action taken!"
    exit 0
fi

tag="$1"

configFile=/opt/SolarWinds/Snap/etc/config.yaml

if [ ! -f /opt/SolarWinds/Snap/etc/config.yaml ]; then
    echo "Error: Can't find $configFile";
    exit 1
fi


tagsStart=$(grep -ns tags: $configFile  | cut -f1 -d:)
tagsInsertLine=$((tagsStart+1))

sed -n  "$tagsStart,5000p" $configFile | grep -v "#" | grep -q "/:"

if [ $? -gt 0 ]; then

    tagsLine="$(grep -m1 tags: $configFile | sed 's# #_#g')";
    depth=$(echo $tagsLine | awk -F_ '{print NF-1}')

    indent=""; for i in $(seq 1 $depth); do indent="$indent\ "; done;
    sed -i "${tagsInsertLine}i${indent}${indent}/:" $configFile
    tagsInsertLine=$((tagsInsertLine+1))
    sed -i "${tagsInsertLine}i${indent}${indent}${indent}environment: $tag" $configFile

else
    sed -i "s#environment:.*#environment: $tag#" $configFile
fi