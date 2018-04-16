#!/bin/bash

#-------------------------------------------------------------------------------
# Synchronize local FAI configuration with remote server
#-------------------------------------------------------------------------------


# list of actual CIP-server hostnames, modify if needed
hostnames=( "host1" "host2" )

# path to FAI directory
FAI="/srv/fai/config/"

# connect to server as a non-root user
user="$SUDO_USER"

# preserve these items from overwriting, paths are relative to $FAI
#exclude_list=( "dir1" "dir2" )

# check if running with sudo permissions
# need them to overwrite $FAI contents
if [[ ! $(id -u) -eq 0 ]]; then echo "Use sudo to run this script."; exit 1; fi

# generate temporary file with exclusion list (for rsync)
printf "%s\n" "${exclude_list[@]}" > /tmp/rsync_exclude

# hostname mapping procedure (simple separate definition, no encapsulation etc.)
function set_hostname {
    server=$(hostname)
    if [[ $server == ${hostnames[0]} ]]; then src="${hostnames[1]}";
    elif [[ $server == ${hostnames[1]} ]]; then src="${hostnames[0]}";
    else
	echo "   Please specify a remote server to use as a source"
	echo "   Destination server hostname should be either" "${hostnames[0]}" "or" "${hostnames[1]}."
	echo "   Please check your hostname first or define source server address as first argument of this script."
	echo
	echo "   Usage: sudo pull.sh remoteserver"
	exit 1
    fi
}

echo


# decide which remote server to use
if [[ -n "$1" ]]; then src="$1"; else set_hostname; fi
echo "   -> Source server set to" "$(tput setaf 2)${src}$(tput sgr0)."

echo


# backup previous configuration
echo "   -> Backing up previous configuration to $FAI/backup..."

if [[ ! -d $FAI/backup ]]; then
    mkdir "$FAI/backup"
    echo "   -> Created directory $FAI/backup"
fi

echo

if rsync -avuz "$FAI/" "$FAI/backup/"; then
    echo && echo "   $(tput setaf 2)-> Backup done.$(tput sgr0)"
else
    echo && echo "   $(tput setaf 1)-> Couldn't create backup!.$(tput sgr0)"
    echo && exit 1
fi

echo 


# cloning procedure
echo "   -> Excluding following paths from syncing: ${exclude_list[*]}"

echo

echo "   -> Started synchronization."

echo

if rsync -avuz --exclude-from "/tmp/rsync_exclude" --delete "$user@$src:$FAI/*" "$FAI" &&
    rsync -avuz --delete "$user@$src:/usr/local/bin/*" "/usr/local/bin/"; then
    echo && echo "   $(tput setaf 2)-> Synchronization done.$(tput sgr0)"
else
    echo && echo "   $(tput setaf 1)-> Synchronization terminated with errors!.$(tput sgr0)" 
    echo && exit 1
fi

echo


exit 0

