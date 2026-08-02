@echo off
cd %1
REM vc6
del /q *.log
REM vc6
del /q *.opt
REM vc6
del /q *.plg
REM vc6/v05
del /q *.ncb
REM vs05/vs10
del /q *.ncb
REM vs05/vs10/vs19/vs22
del /q *.user
REM vs13
del /q *.opensdf
REM vs13
del /q *.sdf
REM vs13/v15/vs19/vs22
del /q /a:H *.suo
REM vs15
del /q *.db
REM vs15/vs19/vs22
rmdir /s /q .\.vs
REM vc6/vs05/vs10/vs13/vs15/vs19/vs22
rmdir /s /q .\debug
rmdir /s /q .\release
cd ..

