###############################################################################
#
# Tcl Error Stack
# ===============
# 
# Keeps track of changes in ::errorInfo and parse them into separate errors.
# This way it's possible to maintain a list of errors ocurred.
#
# Usage:
# ------
# - source starts the tracking
# - dev::printErrors -> Prints to stdout the lasts errors tracked
#
# Changing the tracking error:
# ----------------------------
# set dev::maxErrorInfo <new_value>
# dev::_init
#
# WARNING: This will clear the current error stack
#
# -----------------------------------------------------------------------------
#
# Version: 0.3
# Author: Cristián Donoso (cristiandonosoc@gmail.com)
#
# License:
# -----------------------------------------------------------------------------
#
# This code is Public Domain. 
# You are free to copy, modify and distribute as you please.
# If you like it, you can always let me know.
# THIS CODE COMES WITH ABSOLUTELY NO WARRANTY.
#
###############################################################################

namespace eval dev {

    ###########################################################################
    # VARIABLE SETUP
    ###########################################################################
    
    # maxErrorInfo is exclusive
    variable maxErrorInfo 20
    # Circular buffer to hold the last $maxErrorInfo errors
    variable errorArray
    variable errorArrayIndex
    variable pastErrorInfo
    variable currentErrorInfo 

    proc _init {} {
        variable maxErrorInfo

        variable errorArray
        array set errorArray {}
        # Current Index to WRITE TO in the circular buffer
        variable errorArrayIndex 0
        variable pastErrorInfo ""
        variable currentErrorInfo $::errorInfo


        # This enables us to detect changes to the error variable in tcl
        trace vdelete ::errorInfo uw dev::_errorInfoHandling
        trace variable ::errorInfo uw dev::_errorInfoHandling

        # We initialize the errorArray
        for {set i 0} {$i < $maxErrorInfo} {incr i} {
            set errorArray($i) ""
        }
    }

    # We start the tracking
    _init

    ###########################################################################
    # TRACING
    ###########################################################################

    # The way we detect a new error is seeing if the length of the
    # ::errorInfo variable is shorter than the last time it was modified.
    # This means that it was truncated internally, which happens when a new
    # error happened.
    proc _errorInfoHandling {varName arrayIndex op} {
        variable pastErrorInfo
        variable currentErrorInfo

        set pastErrorInfo $currentErrorInfo
        set currentErrorInfo $::errorInfo

        #_debugErrorInfo $varName $arrayIndex $op

        set pastErrorInfoLength [string length $pastErrorInfo]
        set currentErrorInfoLength [string length $currentErrorInfo]
        if {$pastErrorInfoLength > $currentErrorInfoLength} {
            _pushErrorInfo $pastErrorInfo
        }
    }

    proc _pushErrorInfo {errorInfo} {
        variable errorArray
        variable errorArrayIndex
        variable maxErrorInfo

        # We only push if the error is not inserted before
        # Tcl sends a shit-ton of repeated error messages
        set new true
        if {$errorInfo == $::errorInfo} {
            set new false
        }
        if {$new} {
            for {set i 0} {$i < $maxErrorInfo} {incr i} {
                if {$errorArray($i) == $errorInfo} {
                    set new false
                    break
                }
            }
        }

        if {!$new} {
            return
        }

        set errorArray($errorArrayIndex) $errorInfo
        incr errorArrayIndex
        if {$errorArrayIndex >= $maxErrorInfo} {
            set errorArrayIndex 0
        }
    }

    ###########################################################################
    # CLI/OUTPUT
    ###########################################################################

    proc printErrors {{limit ""}} {
        variable errorArray
        variable errorArrayIndex
        variable maxErrorInfo

        if {$limit == ""} {
            set limit [expr {$maxErrorInfo - 1}]
        }

        # We print the last errors
        set i [expr {($errorArrayIndex + 1) % $maxErrorInfo}]
        while {$i != $errorArrayIndex} {
            set errorInfo $errorArray($i)
            if {$errorInfo != ""} {
                _printErrorInfo $limit $errorInfo
            }

            # We maintain the circular buffer index
            incr i
            if {$i == $maxErrorInfo} {
                set i 0
            }

            # We limit the print
            incr limit -1
            if {$limit <= 0} {
                break
            }
        }

        # Print current error info
        _printErrorInfo 0 $::errorInfo
    }

    proc _printErrorInfo {index errorInfo} {
        puts "-------------------------------------------"
        puts "Error #$index:"
        puts $errorInfo
    }

    ###########################################################################
    # DEBUG
    ###########################################################################

    proc _debugErrorInfo {varName arrayIndex op} {
        variable pastErrorInfo
        variable currentErrorInfo

        puts "-----------------------------------------------------"
        puts "$op ERROR HANDLING ON $varName WITH INDEX $arrayIndex"

        puts $::errorInfo
    }
}
