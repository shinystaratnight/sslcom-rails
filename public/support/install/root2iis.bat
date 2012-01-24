echo off
cls
echo ------------------------------------------------------
echo === GLOBALSIGN ROOT CERTIFICATE TRANSFER FOR IIS 4 ===
echo ------------------------------------------------------
echo ----- Now logged in as [%USERNAME%] -----
echo First make sure that
echo - you are logged in as [Administrator]
echo - you have installed all the right root certificates in your IE browser!
pause
%systemdrive%
cd %windir%\system32\inetsrv
cd
echo Now transferring the root certificates from IE to IIS ...
iisca.exe
echo ------------------------------------------------------
echo Push any key to stop the IIS processes
pause
net stop iisadmin /y
echo ------------------------------------------------------
echo Now starting it up IIS again ...
pause
net start iisadmin
net start "World wide web publishing service"