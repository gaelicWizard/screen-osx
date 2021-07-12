#!/bin/bash -c 'echo This file is meant to be sourced.'

#export SCREENDIR="$(defaults read gnu.screen SCREENDIR 2>/dev/null)"
mkdir -p -m u+rwX,go-rwx "${SHELL_SESSION_DIR:=${XDG_STATE_HOME:-$HOME/.}${XDG_STATE_HOME:+/}bash_sessions}"
readonly SHELL_SESSION_DIR

    # Instruct screen to place its sockets and other datas in ~, not /tmp
#export SCREENDIR

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

if isscreen
then
    if isappscreen
    then
        declare -F prompt_command_append >/dev/null || { echo "screen: Unable to manipulate prompt." 1>&2; return; }
        # import my prompt_commands package

        prompt_command_append "_screen_load_environment_for_multiattach_f"
        # Setup some code to synchronise environment from various concurent logins via multi-attached screen

        prompt_command_append "_screen_set_title_f"
        # Clear the screen title when displaying the prompt
        # this won't actually set a blank title, but it enables `shelltitle "\$ |$SHELL:"` dynamic titling
    fi

    alias top="screen 20 top"
    alias su="screen su"
fi
