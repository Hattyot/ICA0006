#!/bin/bash
active_server=$(ceph mgr stat | grep -oP '"active_name": "\K(.*?)(?=\.)')
hostname=$(hostname)

if [ $active_server != $hostname ]; then
  exit 1
fi

ss -ntl | grep ':{{ dashboard_port }} '
exit 0