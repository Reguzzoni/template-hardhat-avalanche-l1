@echo off

for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set datetime=%%I
set yyyy=%datetime:~0,4%
set mm=%datetime:~4,2%
set dd=%datetime:~6,2%
set hh=%datetime:~8,2%
set min=%datetime:~10,2%
set ss=%datetime:~12,2%


set reportFile=./slitherReport/report_%yyyy%_%mm%_%dd%_%hh%_%min%_%ss%.json


slither . --json %reportFile%

echo Report generated: %reportFile%
pause