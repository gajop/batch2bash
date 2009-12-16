@ECHO off
REM Skripta za sintezu
REM
REM
REM Odsek za racunarsku tehniku i medjuracunarske komunikacije
REM Fakultet Tehnickih Nauka
REM Univerzitet Novi Sad
REM Copyright ? 2008 All Rights Reserved
REM

IF "%1" == ""      GOTO SYNTHESIS
IF "%1" == "help"  GOTO HELP
IF "%1" == "clean" GOTO CLEAN

:HELP
ECHO.
ECHO KOMANDA: MAKE.BAT [opcije]
ECHO.
ECHO MOGUCE OPCIJE:
ECHO     MAKE.BAT           POCETAK SINTEZE
ECHO     MAKE.BAT help      PRIKAZ OVE LISTE KOMANDI
ECHO     MAKE.BAT clean     BRISANJE SVIH PRIVREMENIH DATOTEKA
ECHO.
GOTO QUIT

:SYNTHESIS


DEL /q synthesis_log.txt
MD temp      >> synthesis_log.txt
MD xst\work  >> synthesis_log.txt

CLS
DEL /q synthesis_log.txt
ECHO.--- POCETAK RADA -------
DATE /T >> synthesis_log.txt
DATE /T
TIME /T >> synthesis_log.txt
TIME /T
ECHO.------------------------

ECHO.
COLOR E
ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.------------------------ POCETAK SINTEZE -------------------------->> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO -------------------------------------------------------------------
ECHO ------------------------ POCETAK SINTEZE --------------------------
ECHO -------------------------------------------------------------------

xst -ifn xst_options.scr -ofn top.syr -intstyle ise >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_SYNTHESIS

ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.------------------------  KRAJ SINTEZE  --------------------------->> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO.-------------------------------------------------------------------
ECHO.------------------------  KRAJ SINTEZE  ---------------------------
ECHO.-------------------------------------------------------------------

ngdbuild -intstyle ise -dd _ngo -uc top.ucf -p xc3s1500-fg676-4 top.ngc top.ngd >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_TRANSLATE

ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.------------------------ POCETAK MAPIRANJA ------------------------>> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO -------------------------------------------------------------------
ECHO ------------------------ POCETAK MAPIRANJA ------------------------
ECHO -------------------------------------------------------------------

map -intstyle xflow -p  xc3s1500-fg676-4 -timing -logic_opt on -ol high -t 2 -cm timing -pr b -o  top_map.ncd  top.ngd top.pcf >> synthesis_log.txt
REM map -intstyle xflow -p  xc3s1500-fg676-4 -timing -logic_opt on -ol high -t 2 -cm timing -pr b -k 4 -o  top_map.ncd  top.ngd top.pcf >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_MAP

ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.-------------------------- KRAJ MAPIRANJA ------------------------->> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO -------------------------------------------------------------------
ECHO -------------------------- KRAJ MAPIRANJA -------------------------
ECHO -------------------------------------------------------------------

ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.----- POCETAK POZICIONIRANJA I POVEZIVANJA (PLACE AND ROUTE) ------>> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO -------------------------------------------------------------------
ECHO ----- POCETAK POZICIONIRANJA I POVEZIVANJA (PLACE AND ROUTE) ------
ECHO -------------------------------------------------------------------

par -w -intstyle xflow -ol high -t 2  top_map.ncd top.ncd  top.pcf >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_PAR

trce -e 100  top.ncd  top.pcf >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_TRACE

ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.------- KRAJ POZICIONIRANJA I POVEZIVANJA (PLACE AND ROUTE) ------->> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt

ECHO -------------------------------------------------------------------
ECHO ------- KRAJ POZICIONIRANJA I POVEZIVANJA (PLACE AND ROUTE) -------
ECHO -------------------------------------------------------------------

bitgen -intstyle xflow -f top.ut  top.ncd >> synthesis_log.txt
IF ERRORLEVEL 1 GOTO ERROR_BITGEN
GOTO CLEAN_AFTER_SYNTH

:ERROR_SYNTHESIS
COLOR   C
ECHO GRESKA PRILIKOM SINTEZE !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN

:ERROR_TRANSLATE
COLOR C
ECHO GRESKA PRILIKOM SINTEZE !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN


:ERROR_MAP
COLOR C
ECHO GRESKA PRILIKOM MAPIRANJA !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN


:ERROR_PAR
COLOR C
ECHO GRESKA PRILIKOM POZICIONIRANJA I POVEZIVANJA (PLACE AND ROUTE) !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN

:ERROR_TRACE
COLOR C
ECHO GRESKA PRILIKOM PROVERE VRENESKIH OGRANICENJA (TRACE) !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN

:ERROR_BITGEN
COLOR C
ECHO GRESKA PRILIKOM GENERISANJA FAJLA ZA PROGRAMIRANJE FPGA !!!
ECHO POGLEDATI synthesis_log.txt
PAUSE
GOTO CLEAN

:CLEAN
DEL /q  *.stx
DEL /q  *.ucf.untf
DEL /q  *.mrp
DEL /q  *.nc1
DEL /q  *.ngm
DEL /q  *.prm
DEL /q  *.lfp
DEL /q  *.placed_ncd_tracker
DEL /q  *.routed_ncd_tracker
DEL /q  *.pad_txt
DEL /q  *.twx
DEL /q  *.log
DEL /q  *.vhd~
DEL /q  *.dhp
DEL /q  *.jhd
DEL /q  *.cel
DEL /q  *.ngr
DEL /q  *.ngc
DEL /q  *.ngd
DEL /q  *.syr
DEL /q  *.bld
DEL /q  *.pcf
DEL /q  *_map.mrp
DEL /q  *_map.ncd
DEL /q  *_map.ngm
DEL /q  *.ncd
DEL /q  *.pad
DEL /q  *.par
DEL /q  *.xpi
DEL /q  *_pad.csv
DEL /q  *_pad.txt
DEL /q  *.drc
DEL /q  *.bgn
DEL /q  *.xml
DEL /q  *_build.xml
DEL /q  *.rpt
DEL /q  *.gyd
DEL /q  *.mfd
DEL /q  *.pnx
DEL /q  *.vm6
DEL /q  *.jed
DEL /q  *.err
DEL /q  tmperr.err
DEL /q  *.bak
DEL /q  *.vhd~
DEL /q  *.zip
DEL /q  *_backup
DEL /q  *.*log
DEL /q  *.map
DEL /q  *.unroutes
DEL /q  *.html
DEL /q  impactcmd.txt
DEL /q  download.xsvf
DEL /q  impact_script.cmd
DEL /q  *.bin
DEL /q  *.bit
DEL /q  *.lso
DEL /q  *.twr
DEL /q  top_vhdl.prj
DEL /q  *.xrpt
DEL /q  *.ise

DEL /q  *.ptwx
RMDIR /s /q temp
RMDIR /s /q xst
RMDIR /s /q _ngo
RMDIR /s /q xlnx_auto_0_xdb
GOTO QUIT

:CLEAN_AFTER_SYNTH
DEL /q  *.stx
DEL /q  *.ucf.untf
DEL /q  *.mrp
DEL /q  *.nc1
DEL /q  *.ngm
DEL /q  *.prm
DEL /q  *.lfp
DEL /q  *.placed_ncd_tracker
DEL /q  *.routed_ncd_tracker
DEL /q  *.pad_txt
DEL /q  *.twx
DEL /q  *.log
DEL /q  *.vhd~
DEL /q  *.dhp
DEL /q  *.jhd
DEL /q  *.cel
DEL /q  *.ngc
DEL /q  *.ngd
DEL /q  *.syr
DEL /q  *.bld
DEL /q  *_map.mrp
DEL /q  *_map.ncd
DEL /q  *_map.ngm
DEL /q  *.pad
DEL /q  *.par
DEL /q  *.xpi
DEL /q  *_pad.csv
DEL /q  *_pad.txt
DEL /q  *.drc
DEL /q  *.bgn
DEL /q  *.xml
DEL /q  *_build.xml
DEL /q  *.rpt
DEL /q  *.gyd
DEL /q  *.mfd
DEL /q  *.pnx
DEL /q  *.vm6
DEL /q  *.jed
DEL /q  *.err
DEL /q  tmperr.err
DEL /q  *.bak
DEL /q  *.vhd~
DEL /q  *.zip
DEL /q  *_backup
DEL /q  *.*log
DEL /q  *.map
DEL /q  *.unroutes
DEL /q  *.html
DEL /q  impactcmd.txt
DEL /q  download.xsvf
DEL /q  impact_script.cmd
DEL /q  *.bin
DEL /q  *.lso
DEL /q  *.twr
DEL /q  *.xrpt
DEL /q  *.ise
DEL /q  *.ptwx
DEL /q  top_vhdl.prj

RMDIR /s /q temp
RMDIR /s /q xst
RMDIR /s /q _ngo
RMDIR /s /q xlnx_auto_0_xdb
ECHO.
ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO.------- USPESNO GENERISAN FAJL ZA PROGRAMIRANJE FPGA -------------->> synthesis_log.txt
ECHO.------------------------------------------------------------------->> synthesis_log.txt
ECHO -------------------------------------------------------------------
ECHO ------- USPESNO GENERISAN FAJL ZA PROGRAMIRANJE FPGA --------------
ECHO -------------------------------------------------------------------
:QUIT
COLOR A
ECHO.------------------------------------------------------------------------------>> synthesis_log.txt
ECHO.------------------------   ZAVRSETAK RADA SKRIPTI   -------------------------->> synthesis_log.txt
ECHO.------------------------------------------------------------------------------>> synthesis_log.txt
ECHO ------------------------------------------------------------------------------
ECHO ------------------------   ZAVRSETAK RADA SKRIPTI   --------------------------
ECHO ------------------------------------------------------------------------------
ECHO.
ECHO.----- KRAJ RADA --------
DATE /T >> synthesis_log.txt
DATE /T                      
TIME /T >> synthesis_log.txt
TIME /T                      
ECHO.------------------------
ECHO.
PAUSE.
COLOR 

