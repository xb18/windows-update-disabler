:: Author: tsgrgo

@echo off

:: Get admin and system privileges
if not "%1"=="admin" (powershell start -verb runas '%0' admin & exit /b)
if not "%2"=="system" (
	mode con: cols=120 && powershell -NoProfile -Command "$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120,30)"
	schtasks /Create /tn "%~nx0" /tr "'%~f0' admin system > '%temp%\%~nx0' && timeout /t 1 && del '%temp%\%~nx0'" /sc ONCE /st 00:00 /rl HIGHEST /f /ru SYSTEM
	schtasks /Run /tn "%~nx0" && schtasks /Delete /tn "%~nx0" /f
	powershell -NoProfile -Command "Get-Content '%temp%\%~nx0'; Get-Content '%temp%\%~nx0' -Wait -Tail 0 -ErrorAction SilentlyContinue"
	pause && exit /b
)

:: Restore renamed services
for %%i in (wuaueng) do (
	takeown /f C:\Windows\System32\%%i_BAK.dll && icacls C:\Windows\System32\%%i_BAK.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i_BAK.dll %%i.dll
	icacls C:\Windows\System32\%%i.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i.dll /remove *S-1-1-0
)

:: Change service config
sc config wuauserv start= auto

echo.
echo Enabled Windows Update Service
echo You can now use software that relies on the Windows Update Service.
echo When finished, you can run the disabler again.
echo More info in README
echo.
