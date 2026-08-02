@echo off
REM _clean.bat
REM   Remove all build files.
REM   Remove all executable files.
REM

if %1.==/?. goto ERROR
if %1.==. goto ALL
if %1.==all. goto ALL
goto ASXXXX

:ALL
call _prep
del /q ..\exe\*.exe
goto EXIT

:ASXXXX
if not exist %1 then goto ERROR
call _prep %1
del /q ..\exe\%1.exe
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

