#!/bin/bash --login

###
## COPYRIGHT John Davidorff Pell
## 2021-07-12
###

##
# Be strict
##

if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then # We are *not* being sourced inside a shell instance.
	set -e # Script dies if any execution failure is unhandled.
	set -u # Script dies if any undefined parameter is referenced.
	shopt -so pipefail # command pipeline fails if *any* command fails
fi


##
#
function slogin () 
{
	# slogin() is meant to start a new login shell on a remote host,
	#  so it will run the slogin command (ssh) and run screen on the
	#  remote host. If we're running within screen(1), then open a
	#  new window.

	local i TITLE SCREENPID SCREENCLI SCREEN_CLI SCREEN_COMMAND

	local SCREEN_COMMAND_DEFAULT="screen -A -U -xRR -e^Aa -p + -S gnu.screen"

	if declare -F isscreen >/dev/null && isscreen
	then
		# The last word on the command line is the host name,
		#  since this slogin() function does run a remote command
		#  and the remote command follows the host name immediately.
		for i in "$@"
		do
			# $# == argc
			TITLE="$i"
			# This is a hack to get the last word on the command line
			#TODO:FIXME: Just get the last word. 
		done

		SCREENPID="${STY%%.*}"
		SCREENCLI="$(ps -xo pid,command | fgrep "${SCREENPID:=$$}" | fgrep -v fgrep)"
		SCREEN_CLI="${SCREENCLI## }" # remove whitespace...?
		SCREEN_COMMAND="${SCREEN_CLI/#${SCREENPID} SCREEN/screen}"
			# Get the command line of the running screen session to use as the command line for the remote.
			# this don't work due to starting screen in the background with -Dm...

		screen -t "$TITLE" slogin -t "$@" exec '"${SHELL:-/bin/bash}"' --login -c '"exec '"${SCREEN_COMMAND_DEFAULT}"'"'
	else
		command slogin -t "$@" exec '"${SHELL:-/bin/bash}"' --login -c '"exec '"${SCREEN_COMMAND_DEFAULT}"'"'
	fi
		# Note that both the entire ${SHELL… expression and the screen(1) expression are single-quoted, so that the local shell does not evaluate them.
		# This should run (1) if screen is available, a new screen window entitled with the hostname; (2) ssh, told to allocate a tty; (3) _exec_ the shell with --login, so as to ensure that screen(1) is run within a proper login shell, and so as to avoid a heirarchy of useless ${SHELL}s; (4) _exec_ screen told to re-attach, violently if necessary, but with minimal violence, again so as to avoid a heirarchy of useless ${SHELL}s.
}
##


##
# store_environment stores selected variables from the pre-attach environment
# Sets global SHELL_SESSION_FILE
# Reads global STY
# Sets global ENVIRONMENTSTACK
##
function store_environment ()
{
	##
	# Create a new, randomly named, file to store the environment for this session
	##

	SHELL_SESSION_FILE="$(mktemp "${SHELL_SESSION_DIR}/session.XXXXXX")"
	##
	
	
	##
	# Store incoming environment information into the file just created, for use inside screen by `_screen_load_environment_for_multiattach_f`
	##
	echo "LOGGED_IN=\"`date`\"" >> "${SHELL_SESSION_FILE}"
		# When did I log in (this time)?

	echo "screen -qX setenv SCREEN \"${TERM:-}\";export SCREEN=\"${TERM:-}\"" >> "${SHELL_SESSION_FILE}"
	echo "screen -qX setenv LANG \"${LANG:-}\";export LANG=\"${LANG:-}\"" >> "${SHELL_SESSION_FILE}"
	echo "screen -qX setenv DISPLAY \"${DISPLAY:-}\";export DISPLAY=\"${DISPLAY:-}\"" >> "${SHELL_SESSION_FILE}"
	echo "screen -qX setenv SSH_AUTH_SOCK \"${SSH_AUTH_SOCK:-}\";export SSH_AUTH_SOCK=\"${SSH_AUTH_SOCK:-}\"" >> "${SHELL_SESSION_FILE}"
	echo "screen -qX setenv SSH_CONNECTION \"${SSH_CONNECTION:-}\";export SSH_CONNECTION=\"${SSH_CONNECTION:-}\"" >> "${SHELL_SESSION_FILE}"
	echo "screen -qX setenv TERM_SESSION_ID \"${TERM_SESSION_ID:-}\";export TERM_SESSION_ID=\"${TERM_SESSION_ID:-}\"" >> "${SHELL_SESSION_FILE}"
	

	echo "export LOGGTIME=\"`date +%s`\"" >> "${SHELL_SESSION_FILE}"
		# Add the creation time of this file
	##

	ENVIRONMENTSTACK="${SHELL_SESSION_DIR}/${theSTY}.environment_stack"

	echo " ${SHELL_SESSION_FILE}" >> "$ENVIRONMENTSTACK"
		# Add this new environment file to the top of the environment stack
}


##
# environment_cleanup cleans up after store_environment
# Reads global SHELL_SESSION_FILE
# Reads global ENVIRONMENTSTACK
##
function environment_cleanup ()
{
	perl -pi -e 's;'"${SHELL_SESSION_FILE}"';;g' "$ENVIRONMENTSTACK"
		# Remove the current environment file from the stack
		# Note, it may not be the top of the stack

	command rm -f "${SHELL_SESSION_FILE}"
		# Delete the environment file for this session, since we're done
		# Don't use any functions/aliases
		# Don't prompt
	
	if [ "$(uniq "$ENVIRONMENTSTACK")" == " " ]
		# If the stack file consists of entirely blank lines, then delete it
	then
		command rm -f "$ENVIRONMENTSTACK"
	fi
}

## Screen
function isscreen ()
{
	if [ -n "${STY:-}" ]
		then return 0;
		else return 1;
	fi
}

function isappscreen ()
{
	if echo "${STY:-}" | grep 'gnu.screen' >/dev/null
		then return 0
		else return 1
	fi 
}

function _screen_print_dcs_f ()
{ # print "device control string" directly to the terminal emulator
	if isscreen;
	then
		printf '\eP%s\e\\' "$@"
	else
		printf "$@"
	fi
}

function _screen_set_title_f ()
{
	printf "\ek${1:-}\e\\"
}

function _screen_load_environment_for_multiattach_f ()
{
	local ENV CURRENV CURRTIME
	local ENVIRONMENTSTACK="${SHELL_SESSION_DIR}/${STY:-}.environment_stack"

	if [ -r "${ENVIRONMENTSTACK}" ]
	then 
		#CURRTIME=`date +%s`
	
		ENV=( `< "${ENVIRONMENTSTACK}"` )
		
		CURRENV="$((${#ENV[@]} -1))"

		[ "$CURRENV" -lt 0 ] && return
	
		if [ -f "${ENV[$CURRENV]}" ]; then
			#eval unset "${SCREEN_ENV_VARIABLES[@]}"
			unset SCREEN LANG DISPLAY SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION
			. "${ENV[$CURRENV]}"
		fi
	fi
}
##

: "${SCREENDIR:=${TMPDIR:-$HOME}/.screen}"
	# Set SCREENDIR to $TMPDIR/.screen, which seems to be the default in Apple's version. (Default from upstream is /tmp/uscreens/S-$LOGNAME .)
: "${SCREENRC:=${XDG_CONFIG_HOME:-$HOME/.}${XDG_CONFIG_HOME:+/}screenrc}"
	# Set SCREENRC to the default location to ensure we can reference it properly
export SCREENDIR SCREENRC

mkdir -p -m u+rwX,go-rwx "${SHELL_SESSION_DIR:=${XDG_STATE_HOME:-$HOME/.}${XDG_STATE_HOME:+/}screen_sessions}"
readonly SHELL_SESSION_DIR

if [ -n "${TERM_SESSION_ID:=${WINDOWID:-}}" ]
then
	export SHELL_SESSION_DID_INIT=1 SHELL_SESSIONS_DISABLE=1
		# Inform Apple Terminal that we do our own sessions.
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then # We are the executing script.

##
# If we've found the right session, then store environment and attach!
##

theSTY="gnu.screen"

trap environment_cleanup EXIT
	# This script needs to cleanup after screen detaches.
shopt -s huponexit
	#  Screen should power-detach at a HUP signal, allowing us to continue.

store_environment

# Start screen
launchctl start gnu.screen || : "Job not found..."
# Attach screen
screen -A -U -xRR -p + -S "${theSTY}"
	# -A Adapt the sizes of all windows to the size of the current terminal.
	# -U tell screen(1) that the tty allows utf-8.
	# -x select an existing session.
	# -RR Really Reconnect (creating a new session if needed).
	# -p + create and select a new window (shell), on screen _above_ 4.0.3.
ret=$? # Save return value

#environment_cleanup
	# See function definition above
##
exit $ret

else # We are being sourced from a shell.
if isscreen
then
	if isappscreen
	then
		safe_append_prompt_command "_screen_load_environment_for_multiattach_f" || { echo "screenAppAttach.sh: Unable to manipulate prompt." 1>&2; return; }
		# Setup some code to synchronise environment from various concurent logins via multi-attached screen

		safe_append_prompt_command "_screen_set_title_f" || { echo "screenAppAttach.sh: Unable to manipulate prompt." 1>&2; return; }
		# Clear the screen title when displaying the prompt
		# this won't actually set a blank title, but it enables `shelltitle "\$ |$SHELL:"` dynamic titling
	fi

	alias top="screen 20 top"
	alias su="screen sudo su -l"
fi
fi
