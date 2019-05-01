@echo OFF

:: Where is the core BUILD ENV
set BENV_CORE=%~dp0
set CONEMUDIR=C:\SVN_source\Tools\ConEmu
set CONFIG=%BENV_CORE%config\ConEmu.xml
set PBCD=%cd%
cd ..
set PTLD=%cd%
set TTLD=C:\SVN_source\Tools

:: Grab the PROJECT_DIR name as the project title
@for %%i in ("%cd%") do @set PROJ_TITLE=%%~ni

call %PBCD%\setup_env.bat

start %CONEMUDIR%\ConEmu64.exe /NoUpdate /Title %PROJ_TITLE% /LoadCfgFile "%CONFIG%" 
