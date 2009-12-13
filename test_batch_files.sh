#!/bin/bash
FILES="*.bat"
if [ ${#FILES} -lt 1 ]; then
    echo -en '\E[40;31m'"[ERROR]"
    tput sgr0
    echo -en '  '
    echo "there are no *.bat files"
    exit
fi
if [ ! -s ./batch2bash ]; then
    echo -en '\E[40;31m'"[ERROR]"
    tput sgr0
    echo -en '  '
    echo "batch2bash must exist and be in the same directory"
    exit
fi
for i in $FILES
do
    echo -n "Parsing file: $i"
    j=${#i}
    while [ $j -lt 70 ]; do
        echo -n " "
        let j=$j+1
    done
    ./batch2bash < $i > $i.output 2> $i.error
    if [ $? != 0 ]; then
        echo -en '\E[40;31m'"[ERROR]"
        tput sgr0
        echo
    else
        echo -en '\E[40;32m'"[OK]"
        tput sgr0
        echo
    fi
done
