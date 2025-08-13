@ECHO Off
chcp 65001 > nul
chcp 1252 > nul
setlocal enabledelayedexpansion

rem begin_file_name:projectid
rem the name is very important for the part of delete old file.
rem ex: sodium-fabric-0.6.13+mc1.21.5.jar -> sodium-fabric:394468
rem set projectid_list=Xaeros_Minimap:263420 XaerosWorldMap:317780 fabric-api:306612 sodium-fabric:394468 iris-fabric:455508
set versionmc=""
set modapi=""
set cfgfile=..\download_mods_config.txt
rem start
set version=1.0
set title=Check last Mods by Flash v%version%
title %title%
echo [36m======================================[0m
echo [36m==== [35m%title% [36m===[0m
echo [36m======================================[0m
SET BINDIR=%~dp0mods\
rem create mods dir if not exist
if not exist %BINDIR% (
  echo [33mCréation du dossier mods.[0m
  md .\mods
)
CD /D "%BINDIR%"

rem add jq if not exist important to take infos in .json files
jq > nul 2>&1
if not !errorlevel! == 2 (
  echo [33mInstallation du paquet jqlang.jq...[0m
  winget uninstall jqlang.jq --nowarn -h
  call :pause 2
  winget install jqlang.jq
  echo [33mInstallation terminé. Veuillez redemarré.[0m
  call :pause 5
  rem start "" "%~f0"
  exit /b 0
)
rem read config file
rem  create config
if not exist %cfgfile% (
  echo [31mFichier de Configuration non trouvé...[0m
  (echo #the begin file name is very important to the part of delete old file.
  echo #ex: sodium-fabric-0.6.13^+mc1.21.5.jar -^> sodium-fabric:394468
  echo #first line mc version and second line mod API (case sensitive^)
  echo 1.21.8
  echo Fabric
  echo #mods, begin_file_name:projectid
  echo #The project ID can be found on curseforge.com mod page
  echo fabric-api:306612) > !cfgfile!
  call :pause 1
  echo [32mFichier de Configuration créer, édité-le avant de continuer...[0m
  call :pause 1
  start "" %cfgfile%
  pause
)
set line=1
for /F "eol=# " %%a in (%cfgfile%) do (
  if !line! == 1 set versionmc="%%a"
  if !line! == 2 set modapi="%%a"
  if !line! GEQ 3 set projectid_list=%%a !projectid_list!
  set /a line=!line!+1
)


rem count many mod
set /a count=0
for %%a in (%projectid_list%) do set /a count=!count!+1
echo [33mIl y a[96m !count! [33mmods pour [96m!modapi:"=![33m...[0m
echo.
call :pause 2
set anynews=0
rem loop each mod
for %%a in (%projectid_list%) do (
  echo [33mVérification des informations pour le mod: [37m%%a[0m
  call :pause 1
  set "modname="
  set "modid="
  for /F "tokens=1,2 delims=:" %%b in ("%%a") do (
    set "modname=%%b"
    set "modid=%%c"
  )
  rem for /F "tokens=2 delims=:" %%b in ("%%a") do set "modid=%%b"
  set filemodinfos=modfile_!modname!.json
  rem download .json
  set url="https://www.curseforge.com/api/v1/mods/!modid!/files?pageIndex=0&pageSize=20&sort=dateCreated&sortDescending=true&removeAlphas=true&gameVersionTypeId=4"
  rem only take modapi
  curl -s --ssl-no-revoke -L !url! | jq -r ".data[] | select(.gameVersions | tostring | contains(\"!modapi!\"))" >!filemodinfos!
  call :pause 2
  rem verify if exist
  set size=0
  FOR %%I in (!filemodinfos!) do set size=%%~zI
  if !size! == 0 (
    echo. [31mLe mod API[36m !modapi! [31minexistant![0m
    call :pause 1
  )
  rem the file infos is valid
  if !size! NEQ 0 (
    rem get infos from .json file with jqlang
    set "filedp="
    set "filename="
    set "datemodified="
    
    call :readinfos .displayName filedp
    call :readinfos .fileName filename
    call :readinfos .dateModified datemodified
    set "datemodified=!datemodified:"=!"
    for /F "tokens=1 delims=T" %%b in ("!datemodified!") do set "datemodified=%%b"
    rem see last file
    echo. [36m!filedp:"=![0m
    echo. [33mDerniere version[37m !filename:"=! [0m^([32m!datemodified![0m^)
  )
  rem delete temporary json
  del !filemodinfos!
  echo.
)
call :decompteXsecs 15
echo [92mA plus.[0m

call :pause 2

endlocal
EXIT /B 0
:readinfos
  set %2=
  set cmd='jq -s ".[0] | %1" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set %2=%%a
EXIT /B 0
:pause
ping 127.0.0.1 -n %1 > nul
EXIT /B 0
:decompteXsecs
SET "BACKSPACE_x7="
set num=%1
for /l %%x in (%num%, -1, 0) do (
  SET /P "DUMMY_VAR=%BACKSPACE_x7%%%x " < NUL
  ping 127.0.0.1 -n 2 > nul
)
echo.
GOTO :EOF