#!/usr/bin/open -e

IMPORTANT: The last time tested, this package is non-functional on Mac OS X v10.6 Snow Leopard. This is due to a change in Apple's libraries which cause screen(1) to exit prematurely when its attempt to move itself to a different bootstrap namespace fails, due to a change in Apple's libraries which prevent changing bootstrap namespace from a job started non-anonymously (i.e., via a plist instead of via LaunchServices or whatever).

INSTALLATION:
    Double-click on SetupScreen.command and THAT'S IT!
    
    This will install three files in your home:
        ~/Tools/screenAppAttach.sh
        ~/.rc.d/screen_app_rc
        ~/Library/LaunchAgents/gnu.screen.plist
    Then, two preferences will be changed:
        com.apple.Terminal/Shell will be set to ~/Tools/screenAppAttach.sh
        "source ~/.rc.d/screen_app_rc" will be added to the end of .bashrc


INFO:

My name is John. I use screen(1) constantly. I wrote a few little tid-bits to make it work a little bit better for me. I hope these help you to. If you make any improvements, please post bugs and patches on http://sourceforge.net/projects/screen-osx .


There are three files in this project:

Screen/screenAppAttach.sh
Screen/screen
Screen/gnu.screen.plist

Screen/screenAppAttach.sh is the heart of the project. Set this as the command to run in Terminal.app (or whatever you use). Then, every time you open a new Terminal window you get attached into your screen session automatically. Ok. Big deal, right? You could just do /usr/bin/screen as your command to run and you'll get the same thing, right? Almost. By attaching through this script, your pre-screen-environment is actually saved into a file before attaching. That's where the second file comes in.

Screen/screen is a snippit from .bashrc. In particular, it sets the PROMPT_COMMAND variable so that the environment saved by screenAppAttach.sh is loaded *inside* screen. Who cares?! Well, if you leave screen running in the background for long periods of time, then you do! If not, then you don't need this package. A little bit smarter: what if you have DISPLAY set differently in different situations, such as... when loggin in via ssh(1)? Well, that's taken care of right here!

Screen/gnu.screen.plist is a launchd(1) plist (for Mac OS X, required) which starts screen such that it isn't a child of your shell, but actually running independently. Sort of a screen-server in the background. This protects against things breaking when you close the first terminal window, due to a broken "bootstrap namespace" (used on Mac OS X for efficient IPC). Note: Mac OS X 10.6 resolves this bug, so this plist becomes much less useful but it is still required due to the architecture of this package.

