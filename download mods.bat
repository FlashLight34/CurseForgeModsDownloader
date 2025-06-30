@ECHO Off
chcp 65001 > nul
chcp 1252 > nul
setlocal enabledelayedexpansion

rem begin_file_name:projectid
rem the name is very important for the part of delete old file.
rem ex: sodium-fabric-0.6.13+mc1.21.5.jar -> sodium-fabric:394468
set projectid_list=Xaeros_Minimap:263420 XaerosWorldMap:317780 fabric-api:306612 sodium-fabric:394468 iris-fabric:455508
set versionmc="1.21.6"
set modapi="Fabric"

rem start
set version=1.2
set title=Mods downloader by Flash v%version%
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
jq -version > nul 2>&1
if not !errorlevel! == 2 (
  echo [33mInstallation du paquet jqlang.jq...[0m
  winget install jqlang.jq
  call :pause 1
  echo [33mInstallation terminé.[0m
  call :pause 2
)

rem get old file and add it to see if already exist
echo [33mVérification des fichiers actuel ...[0m
set "existingmodsfiles="
for %%i in (*.jar) do (
  set "existingmodsfiles=!existingmodsfiles!%%i "
)
rem count many mod
set /a count=0
for %%a in (%projectid_list%) do set /a count=!count!+1
echo [33mIl y a[34m !count! [33mmods pour [34m!modapi:"=![33m et Minecraft version [34m!versionmc:"=![33m...[0m
echo.
call :pause 2
set anynews=0
rem loop each mod
for %%a in (%projectid_list%) do (
  echo [33mVérification des informations pour le mod: [34m%%a[0m
  call :pause 2
  set "modname="
  set "modid="
  for /F "tokens=1 delims=:" %%b in ("%%a") do set "modname=%%b"
  for /F "tokens=2 delims=:" %%b in ("%%a") do set "modid=%%b"
  set filemodinfos=modfile_!modname!.json
  rem download .json
  set url="https://www.curseforge.com/api/v1/mods/!modid!/files?pageIndex=0&pageSize=20&sort=dateCreated&sortDescending=true&removeAlphas=true&gameVersionTypeId=4"
  rem only take versionmc and modapi without snapshot
  rem a testé avec releaseType == 1
  curl -s --ssl-no-revoke -L !url! | jq -r ".data[] | select(.gameVersions | tostring | contains(\"snapshot\") | not) | select(.gameVersions | tostring | contains(\"!versionmc!\") and contains(\"!modapi!\"))" >!filemodinfos!
  call :pause 1
  rem get infos from .json file with jqlang
  set "fileid="
  set "filename="
  set "datemodified="
  set cmd='jq -s ".[0] | .id" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set "fileid=%%a"
  set cmd='jq -s ".[0] | .fileName" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set "filename=%%a"
  set cmd='jq -s ".[0] | .dateModified" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set "datemodified=%%a"
  set "datemodified=!datemodified:"=!"
  for /F "tokens=1 delims=T" %%b in ("!datemodified!") do set "datemodified=%%b"
  rem verify if exist
  set size=0
  FOR %%I in (!filemodinfos!) do set size=%%~zI
  if !size! == 0 (
    echo. [31mInformations introuvable[36m !versionmc! [31mou le mod API[36m !modapi! [31minexistant![0m
    call :pause 2
  )
  rem download the file
  if !size! NEQ 0 (
    echo !existingmodsfiles! | findstr /ilC:!filename! > nul 2>&1
    if !errorlevel! == 1 (
      set /a anynews=!anynews!+1
      echo. [36mNouvelle version [0m^([32m!datemodified![0m^)
      call :pause 2
      call :deleteoldfile !modname!
      call :pause 2
      call :downloadmod !modid! !fileid! !filename!
      call :pause 2
    )
  )
  rem delete temporary json
  del !filemodinfos!
  echo.
)
if !anynews! EQU 0 echo [32mRien de nouveau, a plus.[0m
if !anynews! EQU 1 echo [33mIl y a eu du nouveau, a plus.[0m
if !anynews! GTR 1 echo [33mIl y a eu[36m !anynews! [33mmise a jour, a plus.[0m
call :pause 5

endlocal
EXIT /B 0

:deleteoldfile
for %%i in (%1*.jar) do (
  echo. [31mEffacement de l^'ancien fichier[33m %%i[0m
  del %%i
)
EXIT /B 0
:downloadmod
set mi=%1
set fi=%2
set fn=%3
set url="https://www.curseforge.com/api/v1/mods/%mi%/files/%fi%/download"
set "fn=%fn:"=%"
echo. [35mTéléchargement du mod[33m %fn% [0m^([35mid:[33m %fi%[0m^)
curl -s --ssl-no-revoke -A "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64)" -H "accept: application/json" -L %url% -o "%BINDIR%%fn%"
EXIT /B 0
:pause
ping 127.0.0.1 -n %1 > nul
EXIT /B 0
