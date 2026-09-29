@echo off
title DeskAI Operations - Windows Desktop App Setup
echo ========================================================
echo   DeskAI Operations - Autonomous IT Help Desk Setup
echo ========================================================
echo.
echo Installing DeskAI Desktop Application...
echo.

set TARGET_URL=https://ai-desk-nsg5.vercel.app
set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = oWS.ExpandEnvironmentStrings("%%USERPROFILE%%\Desktop\DeskAI Operations.lnk") >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "chrome.exe" >> %SCRIPT%
echo oLink.Arguments = "--app=%TARGET_URL%" >> %SCRIPT%
echo oLink.Description = "DeskAI Operations - Autonomous IT Help Desk" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%

cscript /nologo %SCRIPT%
del %SCRIPT%

echo [SUCCESS] Desktop Shortcut created successfully on your Desktop!
echo Launching DeskAI Desktop App...
start chrome.exe --app=%TARGET_URL%
pause
