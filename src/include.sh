#!/bin/bash

RUNONCE_SCRIPTS="/usr/share/runonce/scripts"
RUNONCE_TARGETS="/usr/share/runonce/targets"
RUNONCE_DONE_STAMP_DIRECTORY="/var/lib/runonce/done"
RUNONCE_QUEUED_STAMP_DIRECTORY="/var/lib/runonce/queue"
RUNONCE_QUEUED_STAMP="/var/lib/runonce/runonce_queued" # Only used by the systemd-generator

set_user_directories() {
	RUNONCE_QUEUED_USER="${1%%:*}"
	RUNONCE_USER_DIRECTORY="${1#*:}/.runonce"
	RUNONCE_DONE_STAMP_DIRECTORY="${RUNONCE_USER_DIRECTORY}/done"
	RUNONCE_QUEUED_STAMP_DIRECTORY="${RUNONCE_USER_DIRECTORY}/queue"
	RUNONCE_QUEUED_STAMP="${RUNONCE_USER_DIRECTORY}/runonce_queued" # Only used by the systemd-generator

	mkdir -p "${RUNONCE_DONE_STAMP_DIRECTORY}"
	mkdir -p "${RUNONCE_QUEUED_STAMP_DIRECTORY}"
	chown -R "${RUNONCE_QUEUED_USER}" "${RUNONCE_USER_DIRECTORY}"
}

get_homedirs() {
	grep '\/home\/.*\/bin/.*sh' /etc/passwd | awk -F ':' '{ print $1":"$6 }'
}
