# screenAppAttach.sh

## Installation
    Double-click on SetupScreen.command and THAT'S IT!
    
    This will install three files in your home:
        ~/Tools/screenAppAttach.sh
        ~/.rc.d/screen_app_rc
        ~/Library/LaunchAgents/gnu.screen.plist
    Then, two preferences will be changed:
        com.apple.Terminal/Shell will be set to ~/Tools/screenAppAttach.sh
        "source ~/.rc.d/screen_app_rc" will be added to the end of .bashrc


## Background

My name is John. I use screen(1) constantly. I wrote a few little tid-bits to make it work a little bit better for me. I hope these help you to. If you make any improvements, please post bugs and patches on http://sourceforge.net/projects/screen-osx .

There are two files in this project:

1. screenAppAttach.sh
2. gnu.screen.plist

- screenAppAttach.sh
: Set this as the command to run in Terminal.app (or whatever you use). Then, every time you open a new Terminal window you get attached into your screen session automatically. Ok. Big deal, right? You could just do /usr/bin/screen as your command to run and you'll get the same thing, right? Almost. By attaching through this script, your pre-screen-environment is actually saved into a file before attaching. That's where the second file comes in.
: screenAppAttach.sh is also a snippit for .bashrc. In particular, it sets the PROMPT_COMMAND variable so that the environment saved by screenAppAttach.sh is loaded *inside* screen. Who cares?! Well, if you leave screen running in the background for long periods of time, then you do! If not, then you don't need this package. A little bit smarter: what if you have DISPLAY set differently in different situations, such as... when logging in via ssh(1)? Well, that's taken care of right here!

- gnu.screen.plist
: a launchd(1) plist (for macOS X) which starts screen such that it isn't a child of your shell, but actually running independently. Sort of a screen-server in the background.

