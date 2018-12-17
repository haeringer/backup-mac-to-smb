#!/bin/bash

################################################################################
# Script name : backup-mac-to-smb.sh
# Description : Sync local directory on MacOS with SMB share. Auto-manage the
#               mount depending on network connectivity to share.
# Usage       : Run with cron, e.g. once every 5 minutes:
#               */5 * * * * sh backup-mac-to-smb.sh 2>/dev/null
# Author      : Benjamin Haeringer
# Email       : ben.haeringer@gmail.com
# Date        : 2018/03/02
################################################################################

# define source directory within user $HOME, mount location, share & share server address
backupdir="/Documents"
mntpnt="/Users/username/smbshare"
share="//username@smbserver/user-share-dir"
server="smbserver"


# check if share is mounted
if mount | grep "$share" > /dev/null; then
    mounted=1; else mounted=0
fi

# check if share server is reachable via smb
if nc -z "$server" 445 &>/dev/null; then
  srv_ok=1; else srv_ok=0
fi

# mount, unmount or do nothing
if [ $srv_ok == 0 ] && [ $mounted == 0 ]; then
  ready=0
elif [ $srv_ok == 0 ] && [ $mounted == 1 ]; then
  $(command -v umount) "$share" && ready=0
elif [ $srv_ok == 1 ] && [ $mounted == 0 ]; then
  if [ ! -d "$mntpnt" ]; then
    mkdir "$mntpnt"
  fi
  mount_smbfs "$share" "$mntpnt"
  while [ ! -d "$mntpnt$backupdir" ]; do
	  sleep 2
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
  rsync -a --exclude=".git/" --delete --ignore-errors "$HOME$backupdir" "$mntpnt"/ &>/dev/null
else exit 2
fi

exit 0