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
      target_hostname=$(jetpack config cyclecloud.node.name | tr '[:upper:]' '[:lower:]')

      if [[ $n -le $max_retry ]]; then
        if [ "$current_hostname" != "$target_hostname" ]; then
          logger -s "hostname not renamed -  Attempt $n/$max_retry:"
          enforce_hostname $current_hostname $target_hostname
          sleep $delay
        else
          logger -s "hostname successfully renamed"
          break
        fi
        ((n++))
      else
        logger -s "Failed to rename host after $n attempts."
        exit 1
      fi
    done
  fi
}

rename_host
