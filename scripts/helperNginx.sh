#!/bin/bash

action=${1:-install}
echo "Info: action=$action";

now=$(date +%s)

case $action in
uninstall)
    if [ -f /etc/nginx/conf.d/stub_status.conf ]; then
        mv /etc/nginx/conf.d/stub_status.conf /etc/nginx/conf.d/stub_status.conf.$now
    fi
    if [ -f /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml ]; then
        mv /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml.$now;
    fi
;;
install)
    isHttpStubStatusCapable=1; #true

    pidof nginx 2>&1 >/dev/null
    if [ $? -eq 0 ]; then
        nginx -V 2>&1 | grep -o with-http_stub_status_module
        if [ $? -eq 0 ]; then
            if [ -f /etc/nginx/conf.d/stub_status.conf ]; then
                mv /etc/nginx/conf.d/stub_status.conf /etc/nginx/conf.d/stub_status.conf.$now
            fi
            touch /etc/nginx/conf.d/stub_status.conf
            chown jelastic /etc/nginx/conf.d/stub_status.conf
            cat <<EOF > /etc/nginx/conf.d/stub_status.conf
server {
    listen 127.0.0.1:8088;
    listen [::1]:8088;
    server_name  _;

    location /server_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF
        else
            isHttpStubStatusCapable=0; #false
        fi

        if [ -f /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml ]; then
            mv /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml.$now;
        fi
        
        touch /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
        chown solarwinds.solarwinds /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
        cat <<EOF > /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
---
version: 2

schedule:
  type: cron
  interval: "0 * * * * *"

plugins:
  - plugin_name: bridge

    config:
      nginx:
        ## An array of Nginx stub_status URI to gather stats.
EOF
            if [ $isHttpStubStatusCapable -eq 1 ]; then
                echo  "\
        urls:
          - http://localhost:8088/server_status" >> /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
            else
                echo  "\
        #urls:
        #  - http://localhost:8088/server_status" >> /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
            fi
            cat <<EOF >> /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-bridge-nginx.yaml
        ## Optional TLS Config
        # tls_ca: /path/to/cafile
        # tls_cert: /path/to/certfile
        # tls_key: /path/to/keyfile

        ## Use TLS but skip chain & host verification
        # insecure_skip_verify: false

        ## HTTP response timeout (default: 5s)
        response_timeout: "5s"

    publish:
      - plugin_name: publisher-appoptics
EOF
;;
esac
    
jem service reload
jem service restart swisnapd
