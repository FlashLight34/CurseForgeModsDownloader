@ECHO Off
chcp 65001 > nul
chcp 1252 > nul
setlocal enabledelayedexpansion

rem begin_file_name:projectid
rem the name is very important for the part of delete old file.
rem ex: sodium-fabric-0.6.13+mc1.21.5.jar -> sodium-fabric:394468
rem set projectid_list=Xaeros_Minimap:263420 XaerosWorldMap:317780 fabric-api:306612 sodium-fabric:394468 iris-fabric:455508
set versionmc="1.21.8"
set modapi="Fabric"
set cfgfile=..\download_mods_config.txt

rem start
set version=1.4
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

rem  create config file
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
rem read config file

set line=1
for /F "eol=# " %%a in (%cfgfile%) do (
  if !line! == 1 set versionmc="%%a"
  if !line! == 2 set modapi="%%a"
  if !line! GEQ 3 set projectid_list=%%a !projectid_list!
  set /a line=!line!+1
)

rem add jq if not exist important to take infos in .json files
jq > nul 2>&1
if not !errorlevel! == 2 (
  winget uninstall jqlang.jq --nowarn
  echo [33mInstallation du paquet jqlang.jq...[0m
  winget install jqlang.jq
  echo [33mInstallation terminé. Veuillez redemarré.[0m
  call :pause 5
  rem start "" "%~f0"
  exit /b 0
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
echo [33mIl y a[96m !count! [33mmods pour [96m!modapi:"=![33m et Minecraft version [96m!versionmc:"=![33m...[0m
echo.
call :pause 2
set anynews=0
rem loop each mod
for %%a in (%projectid_list%) do (
  echo [33mVérification des informations pour le mod: [37m%%a[0m
  call :pause 2
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
  rem only take versionmc and modapi without snapshot
  rem not work in other case like multi version select(.fileName | tostring | contains(\"!versionmc!\"))
  curl -s --ssl-no-revoke -L !url! | jq -r ".data[] | select(.gameVersions | tostring | contains(\"!versionmc!\") and contains(\"!modapi!\"))" >!filemodinfos!
  call :pause 1
  rem verify if exist
  set size=0
  FOR %%I in (!filemodinfos!) do set size=%%~zI
  if !size! == 0 (
    echo. [31mInformations introuvable[36m !versionmc! [31mou le mod API[36m !modapi! [31minexistant![0m
    call :pause 2
  )
  rem the file infos is valid
  if !size! NEQ 0 (
    rem get infos from .json file with jqlang
    set "fileid="
    set "filename="
    set "datemodified="
    call :readinfos .id fileid
    call :readinfos .fileName filename
    call :readinfos .dateModified datemodified
    set "datemodified=!datemodified:"=!"
    for /F "tokens=1 delims=T" %%b in ("!datemodified!") do set "datemodified=%%b"
    rem look existing files
    echo !existingmodsfiles! | findstr /ilC:!filename! > nul 2>&1
    set result=!errorlevel!
    rem download the file if is new
    if !result! EQU 1 (
      set /a anynews=!anynews!+1
      echo. [36mNouvelle version [0m^([32m!datemodified![0m^)
      call :pause 2
      call :deleteoldfile !modname!
      call :pause 2
      call :downloadmod !modid! !fileid! !filename!
      call :pause 2
    )
    if !result! NEQ 1 (
      echo. Dernière version: [32m!filename:"=![0m
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
:readinfos
  set %2=
  set cmd='jq -s ".[0] | %1" !filemodinfos!'
  for /F "delims=" %%a in (!cmd!) do set %2=%%a
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

