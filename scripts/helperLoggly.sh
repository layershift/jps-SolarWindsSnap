#!/bin/bash

while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case $param in
      include_logs)
        include_logs="$1"
      ;;
      exclude_logs)
        exclude_logs="$1"
      ;;
      token)
        token="$1"
      ;;
      install|uninstall|updateToken)
        action=$param
      ;;
    esac;
done;

logsExcludeArr=();
logsArr=();

function checkInlogsExcludeArr() {
  for file in ${logsExcludeArr[*]}; do
    if [ "$1" == "$file" ]; then echo 0; fi;
  done;
  echo 1;
}

# excluded logs
if [ ! -z "$exclude_logs" ]; then
  while IFS= read line; do
   if [ -f "$line" ]; then logsExcludeArr+=("$line"); else echo "Notice: $line - not found"; fi;
  done <<<"$(printf $exclude_logs)"
fi

# specified logs
if [ ! -z "$include_logs" ]; then
  while IFS= read line; do
    if [ $(checkInlogsExcludeArr "$line") -eq 1 ]; then
      if [ -f "$line" ]; then 
        logsArr+=("$line"); 
      else 
        echo "Notice: $line - not found"; 
      fi;
    fi
  done <<<"$(printf $include_logs)"
fi

echo "logsArr content: ${logsArr[@]}"

    now=$(date +%s)
    
    case $action in
    updateToken)
      if [ "$token" != "" ]; then
        sed "s/token: \".*/token: \"$token\"/g" -i /opt/SolarWinds/Snap/etc/plugins.d/publisher-logs.yaml;
        sed "s/token: \".*/token: \"$token\"/g" -i /opt/SolarWinds/Snap/etc/plugins.d/logs-v2.yaml;
      else
        echo "Error: Token was not specified.";
        exit;
      fi
    ;;
    uninstall)
        if [ -f /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml ]; then
            mv /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml /opt/SolarWinds/Snap/etc/tasks-autoload.d/task-logs-files.yaml.$now;
        fi
    ;;
    install)
        # nignx
        which nginx 2>/dev/null 1>/dev/null
        if [ $? -eq 0 ]; then
            echo "Info: found nginx"
            while IFS= read line; do
              if [ "$(checkInlogsExcludeArr "$line")" == "1" ]; then
                if [ -f "$line" ]; then 
                  logsArr+=("$line"); 
                else 
                  echo "Notice: $line - not found"; 
                fi;
              fi
            done <<<"$(grep -hr /var/log/nginx /etc/nginx/* | awk '{print $2}' | sort | uniq)"

            # fix php-fpm.log group permission
            if [ -f /var/log/nginx/php-fpm.log ]; then chmod g+r /var/log/nginx/php-fpm.log; logsArr+=("/var/log/nginx/php-fpm.log"); fi
        fi

        # apache
        which httpd 2>/dev/null 1>/dev/null
        if [ $? -eq 0 ]; then
            echo "Info: found Apache"

            while IFS= read line; do
              if [ "$(checkInlogsExcludeArr "$line")" == "1" ]; then
                if [ -f "$line" ]; then 
                  logsArr+=("$line"); 
                else 
                  echo "Notice: $line - not found"; 
                fi;
              fi
            done <<<"$(grep -hr /var/log/httpd /etc/httpd/conf* | awk '{print $2}' | sort | uniq)"
        fi

        echo "logsArr content: ${logsArr[@]}"

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
        for file in ${logsArr[*]}; do
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
    *)
      echo "Error: no action $action not valid [install/uninstall]"
      exit 1;
    ;;
    esac
    jem service restart swisnapd


