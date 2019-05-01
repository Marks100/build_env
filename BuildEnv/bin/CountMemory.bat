@echo off
call ../xBuildEnv/setCmdEnv.cmd
cd %PTLD%\TPMS_SWC\PROJ_TrwBuildEnv\BUILD\KBMI17_MM_APP
ruby %PBCD%\bin\count_memory.rb KBMI17_MM_APP.map 
pause
