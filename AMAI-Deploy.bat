@ECHO OFF
REM ---------------------------------------------------------------------------
REM AMAI-Deploy.bat  -  Copie des cartes vers Maps\AMAI puis y installe AMAI
REM
REM Usage :
REM   AMAI-Deploy.bat "<carte.w3x ou dossier de cartes>" [N] [VERSION]
REM
REM   N        0 = sans Commander
REM            1 = avec Commander  (defaut)
REM            2 = AMAI (equipes impaires) contre IA Blizzard (equipes paires)
REM   VERSION  REFORGED (defaut) | TFT | ROC
REM
REM Les cartes sources ne sont JAMAIS modifiees : elles sont copiees dans
REM   %USERPROFILE%\Documents\Warcraft III\Maps\AMAI\<nom du dossier source>\
REM et AMAI est installe sur la copie.
REM ---------------------------------------------------------------------------
SETLOCAL ENABLEDELAYEDEXPANSION
SET "NoDefaultCurrentDirectoryInExePath="
CD /D "%~dp0"

SET "SRC=%~1"
SET "CMDR=%~2"
SET "VER=%~3"
IF "%CMDR%"=="" SET CMDR=1
IF "%VER%"=="" SET VER=REFORGED

IF "%SRC%"=="" (
  ECHO Usage : AMAI-Deploy.bat "<carte.w3x ou dossier>" [0^|1^|2] [REFORGED^|TFT^|ROC]
  EXIT /B 1
)
IF NOT EXIST "Scripts\%VER%\common.ai" (
  ECHO Scripts %VER% absents. Lance d'abord AMAI-Build.bat %VER%
  EXIT /B 1
)

SET "DEST=%USERPROFILE%\Documents\Warcraft III\Maps\AMAI"

IF EXIST "%SRC%\" (
  FOR %%D IN ("%SRC%") DO SET "DEST=%DEST%\%%~nxD"
) ELSE (
  REM carte seule : on reprend le nom du dossier source (ex. Season9)
  FOR %%D IN ("%SRC%") DO SET "SRCDIR=%%~dpD"
  CALL :TRIMSLASH
  FOR %%D IN ("!SRCDIR!") DO SET "DEST=%DEST%\%%~nxD"
)
IF NOT EXIST "!DEST!" MKDIR "!DEST!"
ECHO Destination : !DEST!
ECHO.

SET COUNT=0
SET ERRORS=0
IF EXIST "%SRC%\" (
  FOR /R "%SRC%" %%F IN (*.w3x *.w3m) DO CALL :ONEMAP "%%F"
) ELSE (
  CALL :ONEMAP "%SRC%"
)

ECHO.
ECHO %COUNT% carte^(s^) traitee^(s^), %ERRORS% erreur^(s^).
IF NOT "%ERRORS%"=="0" EXIT /B 1
EXIT /B 0

:TRIMSLASH
IF "!SRCDIR:~-1!"=="\" SET "SRCDIR=!SRCDIR:~0,-1!"
GOTO :EOF

:ONEMAP
SET "MAP=%~1"
ECHO --- %~nx1
COPY /Y "%MAP%" "!DEST!\" >nul
IF ERRORLEVEL 1 (
  ECHO     ECHEC de la copie
  SET /A ERRORS+=1
  GOTO :EOF
)
CALL .\InstallVERToMap.bat %VER% "!DEST!\%~nx1" "%CMDR%"
IF ERRORLEVEL 1 SET /A ERRORS+=1
SET /A COUNT+=1
GOTO :EOF
