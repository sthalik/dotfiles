#/bin/false

set confirm on
set breakpoint pending on
set disassembly-flavor intel
set index-cache enabled
alias line = info line *$rip
alias btall = backtrace -full -frame-arguments all
alias cls = shell clear

# ----------------------

set logging file c:/NUL
set logging overwrite on
set logging redirect on
set logging debugredirect on
set logging enabled on
set breakpoint pending on

catch throw
catch signal
b abort
b _exit
b std::quick_exit
b std::terminate
b raise
b kill

# !!! todo skip

set logging file gdb.txt
set logging overwrite off
set logging redirect off
set logging debugredirect off
set logging enabled off
set breakpoint pending off

# eof
