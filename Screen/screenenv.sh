#!/bin/false

###
## COPYRIGHT John Davidorff Pell
## 27 March 2005
###

##
# This file is deprecated in favor of a function.
##

if [ -r "${SCREENDIR}/environment.$STY" ]; then 
    #CURRTIME=`date +%s`

    ENV=( `< "${SCREENDIR}/environment.$STY"` )

    if [ -f "${ENV[$((${#ENV[@]} -1))]}" ]; then
        #eval unset "${SCREEN_ENV_VARIABLES[@]}"
        unset SCREEN DISPLAY SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION
        . "${ENV[$((${#ENV[@]} -1))]}"
    fi

    unset ENV CURRTIME
fi
