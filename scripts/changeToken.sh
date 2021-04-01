#!/bin/bash

if [ "$1" != "" ]; then sed "s/token: \".*/token: \"$1\"/g" -i /opt/SolarWinds/Snap/etc/plugins.d/*.yaml; fi;