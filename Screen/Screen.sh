#!/bin/sh -l

###
## COPYRIGHT John Davidorff Pell
## 27 March 2005
###

# Hopefully the -l above does what I want :-/
#eval `( [ -r "$HOME/.bash_profile" ] && echo . "$HOME/.bash_profile" ) || ( [ -r "$HOME/.profile" ] && echo . "$HOME/.profile" )`
    # Here I am manually sourcing bash's profile information to ensure that its information is available inside screen. This is because new commands usually need the information set up by the login-shell. If you do not use bash... i'm not sure what to do, since this is a hack to prevent me from having to actually launch a login shell...

export SCREENDIR="${HOME}/.screen"
mkdir -p "$SCREENDIR" || (echo "Unable to create $SCREENDIR";exit -1)
chmod -R u+rwX,go-rwx "$SCREENDIR" || (echo "Unable to set permissions on $SCREENDIR";exit -1)

cd "$HOME" # Normally, applications on Mac OS X are started in the root of the drive, we should move to ~ for our cli apps.

# Clean up ~/.screen
for i in `ls -1 "${HOME}/.screen" | grep environment | perl -pi -e 's/environment.//g'`
    do [ ! -p "${HOME}/.screen/$i" ] && rm "${HOME}/.screen/environment.$i"
done
    # I do not use rm -f because I like informative error messages, and this script will almost never be called with the need to be quite.


echo "Executing `type -p screen`" 2>&1

exec screen -fn -D -m -S app.screen
    # This launches screen:
        # (-fn) with flow control off, 
        # (-D -m) in detached mode, without forking (to keep proper process heirarchy, MacOSX is weird about window server access, and to make sure that it only gets run once (since MacOSX only allows a given app bundle to be executed once at a time (except in odd circumstances))), 
        # (-S app.screen) and names the session "app.screen" to indicate that it was started by Screen.app (this script) (its not named "screen.app" because that would make the created socket file end in ".app", which would then appear to be an application).
