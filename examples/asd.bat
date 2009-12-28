rem will slowly update this script for testing 
rem it should contain exceptions and such 
rem
rem


@ECHO OFF

rem testing redirection translating 
dir  temp      > contentOfTemp.txt
dir  temp >> isAppendingWorking.txt
rem next command doesn't do anything 
echo < isAddpendingWorking.txt
rem test komentara
find "is this working" ao.txt

del asd.txt
rem translating pause as echo && read 
pause
