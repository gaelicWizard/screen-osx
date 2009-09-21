#!/bin/bash -l

###
## COPYRIGHT John Davidorff Pell
## 9 December 2008
###

##
# Be strict
##

#set -e
set -u

##
require screen
    # Import my screen package
        # isscreen
        # isappscreen

##
# store_environment stores selected variables from the pre-attach environment
# Sets global SESSIONENVFILE
# Reads global STY
# Sets global ENVIRONMENTSTACK
##
function store_environment ()
{
    ##
    # Create a new, randomly named, file to store the environment for this session
    ##
    local HOMETEMP="${HOME}/.temp"
    if [ ! -d "$HOMETEMP" ]
    then
        mkdir -m 700 "$HOMETEMP"
    fi

    SESSIONENVFILE="$(mktemp "$HOMETEMP/screen-environment.XXXXXX")"
    ##
    
    
    ##
    # Store incoming environment information into the file just created, for use inside screen by `screenenv.sh'
    ##
    echo "LOGGED_IN=\"`date`\"" >> "${SESSIONENVFILE}"
        # When did I log in (this time)?

    echo "screen -qX setenv SCREEN \"${TERM:-}\";export SCREEN=\"${TERM:-}\"" >> "${SESSIONENVFILE}"
    echo "screen -qX setenv LANG \"${LANG:-}\";export LANG=\"${LANG:-}\"" >> "${SESSIONENVFILE}"
    echo "screen -qX setenv DISPLAY \"${DISPLAY:-}\";export DISPLAY=\"${DISPLAY:-}\"" >> "${SESSIONENVFILE}"
    echo "screen -qX setenv SSH_AUTH_SOCK \"${SSH_AUTH_SOCK:-}\";export SSH_AUTH_SOCK=\"${SSH_AUTH_SOCK:-}\"" >> "${SESSIONENVFILE}"
    echo "screen -qX setenv SSH_CONNECTION \"${SSH_CONNECTION:-}\";export SSH_CONNECTION=\"${SSH_CONNECTION:-}\"" >> "${SESSIONENVFILE}"

    echo "export LOGGTIME=\"`date +%s`\"" >> "${SESSIONENVFILE}"
        # Add the creation time of this file
    ##

    ENVIRONMENTSTACK="${HOME}/.screen/${STY}.environment_stack"

    echo " ${SESSIONENVFILE}" >> "$ENVIRONMENTSTACK"
        # Add this new environment file to the top of the environment stack
}


##
# environment_cleanup cleans up after store_environment
# Reads global SESSIONENVFILE
# Reads global ENVIRONMENTSTACK
##
function environment_cleanup ()
{
    perl -pi -e 's;'"${SESSIONENVFILE}"';;g' "$ENVIRONMENTSTACK"
        # Remove the current environment file from the stack
        # Note, it may not be the top of the stack

    command rm -f "${SESSIONENVFILE}"
        # Delete the environment file for this session, since we're done
        # Don't use any functions/aliases
        # Don't prompt
    
    if [ "$(uniq "$ENVIRONMENTSTACK")" == " " ]
        # If the stack file consists of entirely blank lines, then delete it
    then
        command rm -f "$ENVIRONMENTSTACK"
    fi
}

##
# find_sty asks screen(1) for a suitable $STY
# Sets global STY
##
function find_sty ()
{
    ##
    # Clean the socket dir (this should be optional, to allow for NFS home dirs?)
    # Find the right screen session to use, this should be a passable argument.
    ##
    if screen -q -wipe || [ "$?" -eq 9 ]
    then
        #syslog -s -l Error "There are no usable screen sessions."
        exit 2
    fi
        # Check if there are attachable sessions, and clean dead ones. If not, return early.


    STY="$(screen -ls | fgrep gnu.screen | head -n 1 | awk '{print $1}')"
        # Query screen for a running "$PID.gnu.screen" session, one started by my launchd(1) plist
        
    [ "$STY" ]
        # Bash sets the return value of a function to that of its last command
}

##
# If we've found the right session, then store environment and attach!
##

if ! find_sty
then
    echo 'Unable to locate a suitable screen session!' "'find_sty' == ($?)"
    sleep 1
    exit 1
fi

trap environment_cleanup HUP INT QUIT KILL TSTP
    # This script needs to cleanup after screen detaches, so don't stop executing when receive HUP et al.
    #  HUP is usually caused by a closed window, or a disconnected ssh, &c.
    #  Screen should power-detach at a HUP signal, allowing us to continue.

store_environment
    # See function definition above

# Start screen
screen -xRR -p + "${STY}"
    # -x selects an existing session
    # -RR Really Reconnects (creating a new session if needed)
        # allows a race between find_sty and here...
    # -p + creates and selects a new window (shell)
ret=$? # Save return value

environment_cleanup
    # See function definition above
##

exit $ret
