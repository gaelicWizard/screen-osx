#!/bin/bash --login

###
## COPYRIGHT John Davidorff Pell
## 9 December 2008
###

##
# Be strict
##

#set -e
set -u

: "${SCREENRC:=${XDG_CONFIG_HOME:-$HOME/.}${XDG_CONFIG_HOME:+/}screenrc}"
    # Set SCREENRC to the default location to ensure we can reference it properly

mkdir -p -m u+rwX,go-rwx "${SHELL_SESSION_DIR:=${XDG_STATE_HOME:-$HOME/.}${XDG_STATE_HOME:+/}screen_sessions}"
readonly SHELL_SESSION_DIR

if [ -n "${TERM_SESSION_ID:=${WINDOWID:-}}" ]
then
    export SHELL_SESSION_DID_INIT=1 SHELL_SESSIONS_DISABLE=1
        # Inform Apple Terminal that we do our own sessions.
fi

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

    if [ -r "${SHELL_SESSION_DIR}/environment.${STY:-}" ]
    then 
        #CURRTIME=`date +%s`
    
        ENV=( `< "${SHELL_SESSION_DIR}/environment.${STY:-}"` )
        
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
screen -A -U -xRR -p + -S "${theSTY}"
    # -A Adapt  the  sizes of all windows to the size of the current terminal
    # -U tells screen(1) that the tty allows utf-8.
    # -x selects an existing session
    # -RR Really Reconnects (creating a new session if needed)
    # -p + creates and selects a new window (shell), on screen _above_ 4.0.3
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
        prompt_command_append "_screen_load_environment_for_multiattach_f"
        # Setup some code to synchronise environment from various concurent logins via multi-attached screen

        prompt_command_append "_screen_set_title_f"
        # Clear the screen title when displaying the prompt
        # this won't actually set a blank title, but it enables `shelltitle "\$ |$SHELL:"` dynamic titling
    fi

    alias top="screen 20 top"
    alias su="screen sudo su -l"
fi
fi
