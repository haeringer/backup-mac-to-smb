## Configuring the script variables

Variables to be adjusted in bmtsmb.sh:

    backupdir:         The source directory for the backup
    mntpnt:            A location where the share can be mounted
    share:             Path of the SMB share in "//username@servername/path" format
    server:            The fqdn of the share server

Variables to be adjusted in local.bmtsmb.plist:

    ProgramArguments:  The path where the script is located
    StartInterval:     Interval in seconds for the script to be run
    StandardErrorPath,
    StandardOutPath:   A path/file where the output log can be written to. The job
                       needs to be run as the smb user which is likely not root, so
                       /var/log cannot be used due to missing permissions


## Running the backup job with launchd

Copy the script into the LaunchAgents directory:

    cp local.bmtsmb.plist ~/Library/LaunchAgents

Use lauchctl to activate, list or deactivate the job:

    launchctl load -w ~/Library/LaunchAgents/local.bmtsmb.plist
    launchctl list | grep bmtsmb
    launchctl unload ~/Library/LaunchAgents/local.bmtsmb.plist
