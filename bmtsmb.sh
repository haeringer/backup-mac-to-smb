#!/bin/bash

################################################################################
# Script name : backup-mac-to-smb.sh
# Description : Sync local directory on MacOS with SMB share. Auto-manage the
#               mount depending on network connectivity to share.
# Usage       : Run with cron, e.g. once a minute:
#               */1 * * * * sh backup-mac-to-smb.sh 2>/dev/null
# Author      : Benjamin Haeringer
# Email       : ben.haeringer@gmail.com
# Date        : 2018/03/02
################################################################################

# define source directory location, share & share server address
srcdir="/Users/bhaeringer/Documents"
share="//username@smbserver/user-share-dir"
server="smbserver"

# extract local mount point from df (macos sometimes creates fancy locations)
get_lmp () {
  mntpnt=$(df $share 2>/dev/null | tail -1 | awk '{ print $NF }')
}
get_lmp

# check if share is mounted
if [ -z "$mntpnt" ]; then
  mounted=0; else mounted=1
fi

# check if share server is reachable via smb
if nc -z $server 445 &>/dev/null; then
  srv_ok=1; else srv_ok=0
fi

# mount, unmount or do nothing
if [ $srv_ok == 0 ] && [ $mounted == 0 ]; then
  ready=0
elif [ $srv_ok == 0 ] && [ $mounted == 1 ]; then
  $(command -v umount) "$share" && ready=0
elif [ $srv_ok == 1 ] && [ $mounted == 0 ]; then
  open -g smb:$share && get_lmp
  while [ -z "$mntpnt" ]; do
  sleep 3 && get_lmp
  done
  ready=1
elif [ $srv_ok == 1 ] && [ $mounted == 1 ]; then
  ready=1
else exit 1
fi

# run backup, depending on mount- and rsync job status
if [ $ready == 0 ]; then
  exit 0
elif [ $ready == 1 ]; then
  pgrep -f rsync.*"$mntpnt" &>/dev/null || \
  rsync -a --delete --ignore-errors $srcdir "$mntpnt"/ &>/dev/null
else exit 2
fi

exit 0