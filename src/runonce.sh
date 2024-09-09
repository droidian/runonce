#!/bin/bash
#
# runonce - Run maintenance scripts once
# Copyright (C) 2022 Eugenio "g7" Paolantonio <me@medesimo.eu>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the <organization> nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

source /usr/share/runonce/include.sh

info() {
	echo "I: $@"
}

warning() {
	echo "W: $@" >&2
}

error() {
	echo "E: $@" >&2
	exit 1
}

can_queue() {
	VERSION="${1}"

	[ -e "${RUNONCE_DONE_STAMP_DIRECTORY}/${SCRIPT_NAME}"  ] || return 0

	current_version=$(grep -oP "\d*" ${RUNONCE_DONE_STAMP_DIRECTORY}/${SCRIPT_NAME})
	[ -n "${current_version}" ] || current_version="1"

	[ ${VERSION} -gt ${current_version} ]
	return
}

handle_target() {
	SCRIPT_NAME="${2}"

	[ -e "${RUNONCE_TARGETS}/${SCRIPT_NAME}" ] && target=$(basename $(cat "${RUNONCE_TARGETS}/${SCRIPT_NAME}" | head -n 1))

	if [[ $target =~ "user:" ]]; then
		for user in $(get_homedirs); do
			set_user_directories $user
			"$@"
		done
	else
		"$@"
	fi
}

run() {
	SCRIPT_NAME="${1}"

	info "Running script ${SCRIPT_NAME}"

	[ -e "${RUNONCE_QUEUED_STAMP_DIRECTORY}/${SCRIPT_NAME}" ] || error "${SCRIPT_NAME} not queued"

	# Remove from queue
	VERSION=$(grep -oP "\d*" ${RUNONCE_QUEUED_STAMP_DIRECTORY}/${SCRIPT_NAME})
	[ -n "${VERSION}" ] || VERSION="1"
	rm -f ${RUNONCE_QUEUED_STAMP_DIRECTORY}/${SCRIPT_NAME}

	[ -e "${RUNONCE_SCRIPTS}/${SCRIPT_NAME}" ] || error "Unable to find script ${SCRIPT_NAME}"

	# Execute script
	${RUNONCE_SCRIPTS}/${SCRIPT_NAME}
	exit_code="${?}"

	# Create done stamp file only if the script executed correctly
	# This allows re-queuing on failures
	[ "${exit_code}" == 0 ] && echo "${VERSION}" > ${RUNONCE_DONE_STAMP_DIRECTORY}/${SCRIPT_NAME}

	info "Script executed, exit code is ${exit_code}"

	return ${exit_code}
}

queue() {
	SCRIPT_NAME="${1}"
	VERSION="${2:-1}"

	[ -e "${RUNONCE_SCRIPTS}/${SCRIPT_NAME}" ] || error "Unable to find script ${SCRIPT_NAME}"

	# Queue
	if can_queue "${VERSION}"; then
		echo "${VERSION}" > ${RUNONCE_QUEUED_STAMP_DIRECTORY}/${SCRIPT_NAME}
		touch ${RUNONCE_QUEUED_STAMP}
	fi

	return
}

case "$(basename ${0})" in
	"runonce")
		[ -n "${1}" ] || error "Usage: ${0} <script_name>"

		handle_target run "${1}"
		exit
		;;
	"runonce-queue")
		[ -n "${1}" ] || error "Usage: ${0} <script_name> [VERSION]"

		handle_target queue "${1}" "${2}"
		exit
		;;
	*)
		error "Program ${0} unsupported"
		;;
esac
