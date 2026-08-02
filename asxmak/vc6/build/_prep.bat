@echo off
REM _prep.bat
REM   Remove all build files.
REM

if %1.==/?. goto ERROR
if %1.==. goto ALL
if %1.==all. goto ALL
goto ASXXXX

:ALL
call _purge as1802
call _purge as2650
call _purge as370
call _purge as4040
call _purge as430
call _purge as6100
call _purge as61860
call _purge as6500
call _purge as6800
call _purge as6801
call _purge as6804
call _purge as6805
call _purge as6808
call _purge as6809
call _purge as6811
call _purge as6812
call _purge as6816
call _purge as68cf
call _purge as68k
call _purge as740
call _purge as78k0
call _purge as78k0s
call _purge as8008
call _purge as8008s
call _purge as8048
call _purge as8051
call _purge as8085
call _purge as89lp
call _purge as8x300
call _purge as8xcxxx
call _purge asavr
call _purge ascheck
call _purge ascop4
call _purge ascop8
call _purge asez8
call _purge asez80
call _purge asf2mc8
call _purge asf8
call _purge asgb
call _purge ash8
call _purge asm8c
call _purge asolms40
call _purge aspdp11
call _purge aspic
call _purge asrab
call _purge asrs08
call _purge asscmp
call _purge asst6
call _purge asst7
call _purge asst8
call _purge asst9
call _purge assx
call _purge astlcs90
call _purge asz8
call _purge asz80
call _purge asz280
call _purge aslink
call _purge asxcnv
call _purge asxscn
call _purge s19os9
del /q ..\misc\*.lst
goto EXIT

:ASXXXX
if not exist %1 then goto ERROR
call _purge %1
del /q ..\misc\*.lst
goto EXIT

:ERROR
echo.
echo make - Compiles the ASxxxx Assemblers, Linker, and Utilities.
echo.
echo Valid arguments are:
echo --------  --------  --------  --------  --------  --------
echo all       ==        'blank'
echo --------  --------  --------  --------  --------  --------
echo as1802    as2650    as370     as4040    as430     as6100
echo as61860   as6500    as6800    as6801    as6804    as6805
echo as6808    as6809    as6811    as6812    as6816    as68k
echo as68cf    as740     as78k0    as78k0s   as8008    as8008s
echo as8048    as8051    as8085    as89lp    as8x300   as8xcxxx
echo asavr     ascheck   ascop4    ascop8    asez8     asez80
echo asf2mc8   asf8      asgb      ash8      asm8c     asolms40
echo aspdp11   aspic     asrab     asrs08    asscmp    asst6
echo asst7     asst8     asst9     assx      astlcs90  asz8
echo asz80     asz280
echo --------  --------  --------  --------  --------  --------
echo aslink    asxcnv    asxscn    s19os9
echo --------  --------  --------  --------  --------  --------
echo.
goto EXIT

:EXIT

