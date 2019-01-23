#!/bin/bash

################################################################################
# Script name : backup-mac-to-smb.sh
# Description : Sync local directory on MacOS with SMB share. Auto-manage the
#               mount depending on network connectivity to share.
# Usage       : Run with cron, e.g. once every 5 minutes:
#               */5 * * * * ./bmtsmb.sh 2>/dev/null
#               Write to log file with timestamp:
#               ./bmtsmb.sh | while IFS= read -r line; do echo "$(date)  $line"; done >>/tmp/bmtsmb.log
# Author      : Benjamin Haeringer
# Email       : ben.haeringer@gmail.com
# Date        : 2018/03/02
################################################################################

# define source directory within user $HOME, mount location, share & share server address
backupdir="/Files"
mntpnt="/Users/username/smbshare"
share="//username@smbserver/user-share-dir"
server="smbserver"

echo "Starting backup script: check mount & share server status"

# check if share is mounted
if /sbin/mount | grep "$share" > /dev/null; then
    mounted=1
    echo "Share is mounted"
else
    mounted=0
    echo "Share is not mounted"
fi

# check if share server is reachable via smb
if /usr/bin/nc -z "$server" 445 &>/dev/null; then
    srv_ok=1
    echo "Share server reachable via smb"
else
    srv_ok=0
    echo "Share server not reachable"
fi

# mount, unmount or do nothing
if [ $srv_ok == 0 ] && [ $mounted == 0 ]; then
    ready=0
elif [ $srv_ok == 0 ] && [ $mounted == 1 ]; then
    echo "lost connection to server; unmounting"
    $(command -v umount) "$share" && ready=0
elif [ $srv_ok == 1 ] && [ $mounted == 0 ]; then
    if [ ! -d "$mntpnt" ]; then
        echo "creating mountpoint directory"
        /bin/mkdir "$mntpnt"
    fi
    echo "Mounting share"
    if /sbin/mount_smbfs "$share" "$mntpnt"; then
        while [ ! -d "$mntpnt$backupdir" ]; do
            echo "Waiting for mount to be ready..."
            sleep 2
        done
        echo "Mount ready"
        ready=1
    else
        echo "Mount failed"
        ready=0
    fi
elif [ $srv_ok == 1 ] && [ $mounted == 1 ]; then
    ready=1
else exit 1
fi

# run backup, depending on mount- and rsync job status
if [ $ready == 0 ]; then
    echo "Backup not possible; quit"
    exit 0
elif [ $ready == 1 ]; then
    if /usr/bin/pgrep -f /usr/local/bin/rsync.*"$mntpnt" > /dev/null; then
        echo "Previous backup job still running; quit"
        exit 0
    else
        echo "Running rsync backup..."
       /usr/local/bin/rsync -a --delete --ignore-errors "$HOME$backupdir" "$mntpnt"/
        echo "Done"
    fi
else exit 2
fi

exit 0