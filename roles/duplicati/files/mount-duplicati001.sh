#!/bin/bash
# mount.sh

###############################################################################
# SET YOUR PREFS HERE - READ BELOW BEFORE RUNNING SCRIPT                      #
# RUN AT YOUR OWN RISK, MAKE BACKUPS OF YOUR DATA ALWAYS                      #
#                                                                             #
# PASSWORD: If your password contains symbols, they must be url encoded       #
#           ie: "@" becomes "%40". To encode your password, use this site:    #
#           http://www.opinionatedgeek.com/dotnet/tools/urlencode/Encode.aspx #
#                                                                             #
# SHARES:   Separated with spaces, case sensitive                             #
#           If shares have spaces, use %20 instead of space. ie HD%20Movies   #
#                                                                             #
# ITUNES:   FALSE = Don"t Open, TRUE = Open                                   #
#                                                                             #
# PROTOCOL: afp OR smb   - lowercase                                          #
#                                                                             #
# WAKE:     FALSE = Don't wake, TRUE = Wake                                   #
#           If you select True, server will initiate wake on lan at specified #
#           time. Requires wolcmd in script location, MAC address, subnet and #
#           the times it should wake the server.                              #
#                                                                             #
###############################################################################

#-----------------------------#
# Required for share mounting #
#-----------------------------#

# Debug
#exec >> /var/tmp/mount-duplicati001.log 2>&1

# Script Location
SCRIPTLOCATION="/Users/asterr/Library/Scripts"

# Username for server
USERNAME="asterr"

# Password for server, check notes
PASSWORD="****"

# IP Address/hostname for ping
PING="192.168.2.143"

# Hostname for server. Try sername.local, hostname or IP
HOSTNAME="192.168.2.143"

# Protocol in lowercase, afp or smb
PROTOCOL="smb"

# Shares, check notes
SHARES="duplicati001 Public"


##############################
# Don"t edit past this point #
##############################

# Mountpoint - Don't edit this unless you know what you're doing.
MOUNT="/Users/asterr/nasmounts"

# Check if server is available
if ( ping -q -c 5 $PING ); then

  AVAILABLE="TRUE"

  # Loop through shares to mount them
  for s in $SHARES ; do

    # Parse spaces for mkdir
    SPACESHARE=$(echo $s|sed "s/%20/ /g")

    # Check to see if mount doesn't exist, then mounts either AFP or SMB.
    if [ ! -d "$MOUNT/$SPACESHARE" ]; then
      # Flag: Resume Duplicati
      touch /tmp/resume_duplicati

      # Mount Share
      mkdir "$MOUNT/$SPACESHARE"
      if [ $PROTOCOL == "smb" ]; then
        echo "Mounting $SPACESHARE ..."
        mount_smbfs -o nostreams -s //$USERNAME:$PASSWORD@$HOSTNAME/$s "$MOUNT/$SPACESHARE"
        if [ ! "$?" -eq "0" ]; then
          if [ "$(ls -A "$MOUNT/$SPACESHARE")" ]; then
            echo "Mount failed. Check settings/server. Could not delete $MOUNT/$SPACESHARE as it contains files. Please check."
            echo "*************"
            AVAILABLE="FALSE"

          else
            echo "$SPACESHARE mount failed. Check settings/server. Removing mount point."
            echo "*************"
            rmdir "$MOUNT/$SPACESHARE"
            AVAILABLE="FALSE"

          fi
        fi

      elif [ $PROTOCOL == "afp" ]; then
        echo "Mounting $SPACESHARE"
        mount_afp afp://$USERNAME:$PASSWORD@$HOSTNAME/$s "$MOUNT/$SPACESHARE"
        if [ ! "$?" -eq "0" ]; then
          if [ "$(ls -A "$MOUNT/$SPACESHARE")" ]; then
            echo "Mount failed. Check settings/server. Could not remove $MOUNT/$SPACESHARE as it contains files. Please check."
            echo "*************"
            AVAILABLE="FALSE"

          else
            echo "$SPACESHARE mount failed. Check settings/server. Removing mount point."
            echo "*************"
            rmdir "$MOUNT/$SPACESHARE"
            AVAILABLE="FALSE"

          fi
        fi
      fi

    else
      if ! df "$MOUNT/$SPACESHARE" | grep -q @ ; then
        rm -rf "$MOUNT/$SPACESHARE"
      else
        # If shares are already mounted, don't do anything
        echo "$SPACESHARE already mounted"
      fi
    fi
  done

else
  DATE=`date +%H`
  DATE=`echo $DATE|sed 's/^0*//'`
  AVAILABLE="FALSE"


  # Loop through shares to unmount them, if mounted.
  for s in $SHARES ; do
    # Parse spaces for umount
    SPACESHARE=$(echo $s|sed "s/%20/ /g")

    # Check to see if mount exists, then unmount
    if [ -d "$MOUNT/$SPACESHARE" ]; then
      # Flag: Pause Duplicati
      touch /tmp/pause_duplicati
      (date; /usr/bin/pkill -STOP mono) >> /var/tmp/mono-pkill.log
      echo "Unmounting $SPACESHARE"
      umount "$MOUNT/$SPACESHARE"
      if ! df "$MOUNT/$SPACESHARE" | grep -q @ ; then
        rm -rf "$MOUNT/$SPACESHARE"
      fi
    fi
  done

  if [ $WAKE == "TRUE" ]; then
    if [[ $DATE -ge $HOURSTART && $DATE -lt $HOUREND ]] || [ $1 == "wake" ]; then
      echo "Waking Server"
      $SCRIPTLOCATION/wolcmd $MACADDRESS $PING $SUBNET 4343
    fi
  fi
fi

date
for s in $SHARES; do
  df -h ~/nasmounts/${s}
done

# Pause / Resume Duplicati
if [[ -e "/tmp/resume_duplicati" ]] ; then
  sleep 60
  (date; echo "resume duplicati"; /usr/bin/pkill -CONT mono) >> /var/tmp/mono-pkill.log
  (/bin/ps -o state,pid,comm -p `/usr/bin/pgrep mono`) >> /var/tmp/mono-pkill.log
  rm -f /tmp/resume_duplicati
fi

if [[ -e "/tmp/pause_duplicati" ]] ; then
  (date; echo "pause duplicati"; /usr/bin/pkill -STOP mono) >> /var/tmp/mono-pkill.log
  (/bin/ps -o state,pid,comm -p `/usr/bin/pgrep mono`) >> /var/tmp/mono-pkill.log
  rm -f /tmp/pause_duplicati
fi
