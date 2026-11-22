@ECHO OFF
REM ---------------------------------------------------------------------------
REM AMAI-Build.bat  -  Compile les scripts AMAI sans exiger Strawberry Perl 5.30
REM
REM Identique a MakeREFORGED.bat / MakeVERBase.bat, mais saute le controle de
REM version de perlcheck.bat : le Perl livre avec Git for Windows (5.26) compile
REM AMAI sans probleme (seuls File::Copy / strict / warnings sont utilises).
REM
REM Usage :  AMAI-Build.bat [REFORGED|TFT|ROC]      (defaut : REFORGED)
REM Resultat : .\Scripts\<VERSION>\
REM ---------------------------------------------------------------------------
SETLOCAL
SET "NoDefaultCurrentDirectoryInExePath="
CD /D "%~dp0"

SET VER=%~1
IF "%VER%"=="" SET VER=REFORGED

where perl >nul 2>&1
IF ERRORLEVEL 1 (
  ECHO Perl introuvable. Installe Git for Windows ou https://strawberryperl.com/
  EXIT /B 1
)
IF NOT EXIST "%VER%\common.j" (
  ECHO Version inconnue : %VER%  ^(attendu REFORGED, TFT ou ROC^)
  EXIT /B 1
)

SET FAILED=0
MKDIR "Scripts\%VER%" 2>nul
MKDIR "Scripts\%VER%\vsai" 2>nul
MKDIR "%VER%\tmp" 2>nul

ECHO [1/4] common.ai
perl ejass.pl common.eai %VER% VER:%VER% > "Scripts\%VER%\common.ai"
.\pjass.exe "%VER%\common.j" "Scripts\%VER%\common.ai" || SET FAILED=1

FOR %%R IN (ELF HUMAN ORC UNDEAD) DO CALL :BUILDRACE %%R

ECHO [3/4] decoupage de blizzard.j
perl SplitBlizzardJ.pl %VER%

ECHO [4/4] Blizzard.j ^(vsai puis commander^)
perl ejass.pl Blizzard3VAI.eai %VER% VER:%VER% > "%VER%\tmp\Blizzard3Gen.j"
perl ejass.pl Blizzard.eai %VER% VER:%VER% > "Scripts\%VER%\vsai\Blizzard.j"
.\pjass.exe "%VER%\common.j" "Scripts\%VER%\vsai\Blizzard.j" || SET FAILED=1
perl ejass.pl Blizzard3.eai %VER% VER:%VER% > "%VER%\tmp\Blizzard3Gen.j"
perl ejass.pl Blizzard.eai %VER% VER:%VER% > "Scripts\%VER%\Blizzard.j"
.\pjass.exe "%VER%\common.j" "Scripts\%VER%\Blizzard.j" || SET FAILED=1

RMDIR /S /Q "%VER%\tmp" 2>nul

IF "%FAILED%"=="1" (
  ECHO.
  ECHO *** Compilation AMAI %VER% EN ECHEC ***
  EXIT /B 1
)
ECHO.
ECHO Scripts AMAI %VER% compiles dans Scripts\%VER%\
EXIT /B 0

:BUILDRACE
SET RACE=%~1
FOR %%L IN (%RACE%) DO SET LC=%%L
IF "%RACE%"=="ELF" SET LC=elf
IF "%RACE%"=="HUMAN" SET LC=human
IF "%RACE%"=="ORC" SET LC=orc
IF "%RACE%"=="UNDEAD" SET LC=undead
ECHO [2/4] %LC%.ai
perl ejass.pl races.eai %VER% VER:%VER% %RACE% RACE:%RACE% > "Scripts\%VER%\%LC%.ai"
.\pjass.exe "%VER%\common.j" "Scripts\%VER%\common.ai" "Scripts\%VER%\%LC%.ai" || SET FAILED=1
GOTO :EOF
