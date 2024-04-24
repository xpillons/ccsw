#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/helpers.sh" 
read_os

source $script_dir/../files/$os_release/rename_host.sh

function rename_host() {
  delay=15
  n=1
  max_retry=3

  standalone_dns=$(jetpack config cyclecloud.hosts.standalone_dns.enabled | tr '[:upper:]' '[:lower:]')
  if [[ $standalone_dns != "true" ]]; then
    while true; do
      current_hostname=$(hostname | tr '[:upper:]' '[:lower:]')
      #hostname_in_hosts=$(getent hosts $(ifconfig eth0 | grep "inet " | xargs) | xargs | cut -d ' ' -f2 | tr '[:upper:]' '[:lower:]')
      target_hostname=$(jetpack config cyclecloud.node.name | tr '[:upper:]' '[:lower:]')
      if [[ $n -le $max_retry ]]; then
        nslookup $target_hostname
        if [ $? -eq 1 ]; then
#        if [[ "$current_hostname" != "$target_hostname" || "$target_hostname" != "$hostname_in_hosts" ]]; then
          logger -s "$target_hostname not resolvable -  Attempt $n/$max_retry:"
          enforce_hostname $current_hostname $target_hostname
          sleep $delay
        else
          logger -s "hostname successfully renamed and resolved"
          break
        fi
        ((n++))
      else
        logger -s "Failed to resolved host $target_hostname after $n attempts."
        exit 1
      fi
    done
  fi
}

rename_host
