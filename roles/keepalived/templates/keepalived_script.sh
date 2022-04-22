#!/bin/bash
active_server=$(ceph mgr stat | grep -oP '"active_name": "\K(.*?)(?=\.)')
available=$(ceph mgr stat | grep -oP '"available": \K(\w+)')
hostname=$(hostname)

if [ $available == "false" ]; then
  exit 1
fi

if [ $active_server != $hostname ]; then
  exit 1
fi

ss -ntl | grep ':{{ dashboard_port }} '
exit 0