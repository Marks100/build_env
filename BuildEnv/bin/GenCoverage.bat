@echo OFF
call ../xBuildEnv/setCmdEnv.cmd
sh -l -c "genCoverage"
pause