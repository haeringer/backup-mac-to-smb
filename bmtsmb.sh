#!/bin/bash

################################################################################
# Script name : backup-mac-to-smb.sh
# Description : Sync local directory on MacOS with SMB share. Auto-manage the
#               mount depending on network connectivity to share.
# Author      : Benjamin Haeringer
# Email       : ben.haeringer@gmail.com
# Date        : 2018/03/02
################################################################################

# define source directory within user $HOME, mount location, share & share server address
backupdir="/Files"
mntpnt="/Users/username/smbshare"
share="//username@smbserver/user-share-dir"
server="smbserver"

# wait 2 minutes to prevent smb connection errors after login
echo `date +'[%Y-%m-%d %H:%M:%S]'` "Starting backup script (sleep 2 minutes)"
sleep 120

echo `date +'[%Y-%m-%d %H:%M:%S]'` "Check mount & share server status"

# check if share is mounted
if mount | grep "$share" > /dev/null; then
    mounted=1
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Share is mounted"
else
    mounted=0
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Share is not mounted"
fi

# check if share server is reachable via smb
if nc -z "$server" 445 &>/dev/null; then
    srv_ok=1
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Share server reachable via smb"
else
    srv_ok=0
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Share server not reachable"
fi

# mount, unmount or do nothing
if [ $srv_ok == 0 ] && [ $mounted == 0 ]; then
    ready=0
elif [ $srv_ok == 0 ] && [ $mounted == 1 ]; then
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "lost connection to server; unmounting"
    $(command -v umount) "$share" && ready=0
elif [ $srv_ok == 1 ] && [ $mounted == 0 ]; then
    if [ ! -d "$mntpnt" ]; then
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "creating mountpoint directory"
        mkdir "$mntpnt"
    fi
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Mounting share"
    if mount_smbfs "$share" "$mntpnt"; then
        while [ ! -d "$mntpnt$backupdir" ]; do
            echo `date +'[%Y-%m-%d %H:%M:%S]'` "Waiting for mount to be ready..."
            sleep 2
        done
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "Mount ready"
        ready=1
    else
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "Mount failed"
        ready=0
    fi
elif [ $srv_ok == 1 ] && [ $mounted == 1 ]; then
    ready=1
else exit 1
fi

# run backup, depending on mount- and rsync job status
if [ $ready == 0 ]; then
    echo `date +'[%Y-%m-%d %H:%M:%S]'` "Backup not possible; quit"
    exit 0
elif [ $ready == 1 ]; then
    if pgrep -f rsync.*"$mntpnt" > /dev/null; then
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "Previous backup job still running; quit"
        exit 0
    else
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "Running rsync backup..."
        rsync --archive \
            --exclude={.git/,.venv/} \
            --delete --ignore-errors \
            "$HOME$backupdir" "$mntpnt"/
        echo `date +'[%Y-%m-%d %H:%M:%S]'` "Done"
    fi
else exit 2
fi

exit 0
