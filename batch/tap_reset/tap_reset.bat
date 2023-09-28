@echo off
netsh winsock reset catalog
netsh int ipv4 reset reset.log
netsh int ipv6 reset reset.log
echo A reset is required
pause
shutdown /r /t 0