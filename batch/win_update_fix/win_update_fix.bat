@echo off

net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver

pushd "%WINDIR%"
ren "SoftwareDistribution" "SoftwareDistribution.old"
popd

pushd "%WINDIR%\System32"
ren "catroot2" "catroot2.old"
popd

net start cryptSvc
net start bits
net start msiserver