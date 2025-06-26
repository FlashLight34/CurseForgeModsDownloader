@ECHO Off
chcp 65001 > nul
chcp 1252 > nul
setlocal enabledelayedexpansion
rem setlocal EnableExtensions
rem begin file name:projectid
rem ex: sodium-fabric-0.6.13+mc1.21.5.jar -> sodium-fabric:394468
set projectid_list=Xaeros_Minimap:263420 XaerosWorldMap:317780 fabric-api:306612 sodium-fabric:394468 iris-fabric:455508
set versionmc="1.21.6"
set modapi="Fabric"

SET BINDIR=%~dp0mods\
CD /D "%BINDIR%"
rem echo %BINDIR%
set version=1.0

rem start
set title=Mods downloader by Flash v%version%
title %title%
echo [36m======================================[0m
echo [36m==== [35m%title% [36m===[0m
echo [36m======================================[0m

rem add jq if not exist
jq -version > nul 2>&1
if not !errorlevel! == 2 (
  echo [33mInstallation du paquet jqlang.jq...[0m
  winget install jqlang.jq
  call :pause 2
  echo [33minstallation terminé.[0m
)

rem get old file and add a contain to see if already exist
echo [33mVérification des fichiers actuel ...
set "existingmodsfiles="
for %%i in (*.jar) do (
  set "existingmodsfiles=!existingmodsfiles!%%i "
)
rem count many mod
set /a count=0
for %%a in (%projectid_list%) do set /a count=!count!+1
echo [33mIl y a[34m !count! [33mmods...
call :pause 2
set anynews=0
rem loop many file
for %%a in (%projectid_list%) do (
  echo [33mVérification des informations pour le mod: [34m%%a[0m
  call :pause 2
  set "modname="
  set "modid="
  for /F "tokens=1 delims=:" %%b in ("%%a") do set "modname=%%b"
  for /F "tokens=2 delims=:" %%b in ("%%a") do set "modid=%%b"
  set filemodinfos=modfile_!modname!.json
  set url="https://www.curseforge.com/api/v1/mods/!modid!/files?pageIndex=0&pageSize=20&sort=dateCreated&sortDescending=true&removeAlphas=true&gameVersionTypeId=4"
  curl -s --ssl-no-revoke -L !url! | jq -r ".data[] | select(.gameVersions | tostring | contains(\"!versionmc!\") and contains(\"!modapi!\"))" >!filemodinfos!
  call :pause 1
  rem recheche des infos dans le fichier
  set "fileid="
  set "filename="
  set cmd='jq -s ".[0] | .id" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set "fileid=%%a"
  set cmd='jq -s ".[0] | .fileName" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set "filename=%%a"
  rem verify if exist
  rem if !filemodinfos!
  set size=0
  FOR %%I in (!filemodinfos!) do set size=%%~zI
  if !size! == 0 (
    echo. [31mInformations introuvable[36m !versionmc! [31mou le mod API[36m !modapi! [31minexistant![0m
  )
  rem download the file
  if !size! NEQ 0 (
    echo !existingmodsfiles! | findstr /ilC:!filename! > nul 2>&1
    if !errorlevel! == 1 (
      set anynews=1
      echo. [36mNouvelle version![0m
      call :pause 1
      call :deleteoldfile !modname!
      call :pause 1
      call :downloadmod !modid! !fileid! !filename!
      call :pause 2
    )
  )

  rem delete temporary json
  del !filemodinfos!
)
if !anynews! == 0 echo [32mRien de nouveau, fermeture.[0m
if !anynews! == 1 echo [33mIl y a eu du nouveau, fermeture.[0m
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
