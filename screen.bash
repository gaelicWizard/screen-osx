#!/bin/sh -c 'echo This file is meant to be sourced.'

#export SCREENDIR="$(defaults read gnu.screen SCREENDIR 2>/dev/null)"
mkdir -p -m u+rwX,go-rwx "${SCREENDIR:=~/.screen}" 
    # Instruct screen to place its sockets and other datas in ~, not /tmp
 
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


function _load_screen_environment_for_multiattach_f ()
{
    local ENV CURRENV CURRTIME

    if [ -r "${SCREENDIR}/environment.${STY:-}" ]
    then 
        #CURRTIME=`date +%s`
    
        ENV=( `< "${SCREENDIR}/environment.${STY:-}"` )
        
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
        set -e
        require prompt_commands
        # import my prompt_commands package
        set +e

        prompt_command_append "_load_screen_environment_for_multiattach_f"
        # Setup some code to synchronise environment from various concurent logins via multi-attached screen
    fi

    alias top="screen 20 top"
    alias su="screen su"
fi
