#!/bin/bash

function enforce_hostname() {
  local system_hostname=$1
  local target_hostname=$2

  # ensure the correct hostname (update if necessary)
  echo "ensure the correct hostname (update if necessary)"

  if [ "$system_hostname" != "$target_hostname" ]; then
    logger -s "Warning: incorrect hostname ($system_hostname), it should be $target_hostname, updating"
    hostname $target_hostname
  fi
  if grep -i $system_hostname /etc/hosts; then
    logger -s "Warning: incorrect hostname ($system_hostname) in /etc/hosts, updating"
    sed -i "s/$system_hostname/$target_hostname/ig" /etc/hosts
  fi
  etc_hostname=$(</etc/hostname)
  if [ "$etc_hostname" != "$target_hostname" ]; then
    logger -s "Warning: incorrect /etc/hostname ($etc_hostname), it should be $target_hostname, updating"
    echo $target_hostname > /etc/hostname
  fi

  if ! systemctl restart systemd-networkd; then
    logger -s "failed to restart systemd-networkd"
  fi
}