#!/bin/bash

action=${1:-install}
logs="$2"

echo "Info: action=$action";

# specified logs
if [ ! -z $logs ]; then
  echo "$logs"
  echo "--"
  while IFS= read line; do
   echo $line;
   echo ".";
  done <<<"$(echo $logs)"
fi

# nignx
which nginx 2>/dev/null 1>/dev/null
if [ $? -eq 0 ]; then
    echo "Info: found nginx"
    nginxUser=$(grep "user " /etc/nginx/*conf -h | grep -v "log_format" | awk '{print $NF}' | sed 's#;##g');

fi

    now=$(date +%s)
    
    case $action in
    uninstall)
        if [ -f /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml ]; then
            mv /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml.$now;
        fi
    ;;
    install)
        if [ -f /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml ]; then
            mv /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml.$now;
        fi
        touch /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml
        chown solarwinds.solarwinds /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml
        cat <<EOF > /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml
---
version: 2

schedule:
  type: streaming

plugins:
  - plugin_name: log-files

    config:
      ## An interval for looking for new files matching given pattern(s)
      #new_file_check_interval: 30s

      ## An array of files or filename patterns to watch.
      ##
      ## NOTE: Be careful when attempting to handle snapteld logs
      ## as those might also contain log entries of logs collector
      ## to avoid infinite recurrence effect you should apply exclude pattern below by adding
      ## ".*self-skip-logs-collector.*"
      file_paths:
EOF
#            for file in $(egrep "error_log|access_log" /etc/nginx/*.conf -rh  | awk '{print $(NF-1)}'); do
            # fix php-fpm.log group permission
        chmod g+r /var/log/nginx/php-fpm.log
        for file in $(find /var/log/nginx/ -name "*.log"); do
            if [ -f $file ]; then 
                echo  "\
        - $file" >> /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml
            fi;
        done

        cat <<EOF >> /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml

      ## Provide one or more regular expressions to prevent certain files from being matched.
      #exclude_files_patterns:
      #  - \.\d$
      #  - \.bz2
      #  - \.gz

      ## There may be certain log messages that you do not want to be sent.
      ## These may be repetitive log lines that are "noise" that you might
      ## not be able to filter out easily from the respective application.
      ## To filter these lines, use exclude_patterns with an array or regexes.
      #exclude_lines_patterns:
      #  - exclude this
      #  - \d+ things

    #metrics:
    #  - |log-files|[file]|string_line

    #tags:
    #  "|log-files|[file=/tmp/application.log]|string_line":
    #    sometag: somevalue

    publish:
      - plugin_name: loggly-http-bulk
EOF
        diff /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml.$now
    ;;
    esac
    jem service restart swisnapd


