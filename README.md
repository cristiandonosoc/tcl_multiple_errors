Multiple Tcl Errors
===================

This is a short script that tracks changes to the ::errorInfo variable.
With this, it is possible to detect different errors and store them, so that we can have a backlog of past errors.
The script maintains the history of the last N errors. N is 20 by default, but it is possible to change.

Usage:
------

1. Simply source. With this the tracking is enabled
2. dev::printErrors will output the errors into the stdout

There are other separate options, like changing the amount of errors retained.
Refer to the script file for more info.
