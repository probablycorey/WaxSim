WaxSim
------

WaxSim is a command-line tool which launches an iOS simulator-targeted
application in the iOS simulator.

Installation
------------

You should be able to simply run `xcodebuild` from a clone of this repository
to build and install the `waxsim` binary into `~/bin/`.  The `~/bin/` directory
should exist first.

Usage
-----

Listing the install SDKs:

    waxsim -a

Running a program:

    waxsim -s <sdk-version> <path-to-app>


Output
------

WaxSim tries to redirect the app's console output to STDOUT; however, the
mechanism provided only works for files which have names.  This unfortunately
excludes normal (anoynymous) UNIX pipes.  So this does not work:

    waxsim -s 4.3 foo/bar.app |grep Hello

But you can do this:

    waxsim -s 4.3 foo/bar.app >/tmp/output.txt && grep Hello /tmp/output.txt

