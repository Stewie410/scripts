:: Restart the print spooler

@echo off

net stop Spooler
net start Spooler
exit /b
