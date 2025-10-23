:: Author: tsgrgo
:: Completely disable Windows Update

:: Get admin and system privileges
if not "%1"=="admin" (powershell start -verb runas '%0' admin & exit /b)
if not "%2"=="system" (
	echo "%~f0" admin system ^> "%temp%\%~nx0.log" ^& timeout /t 1 ^& del "%temp%\%~nx0.log" "%temp%\%~nx0" > "%temp%\%~nx0"

  	schtasks /Create /tn "%~nx0" /tr "'%temp%\%~nx0'" /sc ONCE /st 00:00 /rl HIGHEST /f /ru SYSTEM
	schtasks /Run /tn "%~nx0"
	schtasks /Delete /tn "%~nx0" /f

	start /b powershell -NoProfile -command "&{$w=(get-host).ui.rawui;$w.buffersize=@{width=120;height=999};$w.windowsize=@{width=120;height=30};}"
	powershell -NoProfile -Command "Get-Content '%temp%\%~nx0.log' -Wait -Encoding oem -ErrorAction SilentlyContinue"

	pause && exit /b
)

:: Disable update related services
for %%i in (wuauserv, UsoSvc, uhssvc, WaaSMedicSvc) do (
	:retry
	sc config %%i start= disabled
	sc failure %%i reset= 0 actions= ""
	net stop %%i
	(sc query %%i | find "RUNNING" || sc query %%i | find "STOP_PENDING") && timeout /t 2 && goto retry
)

:: Brute force rename services
for %%i in (WaaSMedicSvc, wuaueng) do (
	takeown /f C:\Windows\System32\%%i.dll && icacls C:\Windows\System32\%%i.dll /grant *S-1-1-0:F
	rename C:\Windows\System32\%%i.dll %%i_BAK.dll
	icacls C:\Windows\System32\%%i_BAK.dll /setowner "NT SERVICE\TrustedInstaller" && icacls C:\Windows\System32\%%i_BAK.dll /remove *S-1-1-0
)

:: Update registry
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

:: Delete downloaded update files
erase /f /s /q c:\windows\softwaredistribution\*.* && rmdir /s /q c:\windows\softwaredistribution

:: Disable all update related scheduled tasks
powershell -NoProfile -Command $paths = @( ^
'\Microsoft\Windows\InstallService*', ^
'\Microsoft\Windows\UpdateOrchestrator*', ^
'\Microsoft\Windows\UpdateAssistant*', ^
'\Microsoft\Windows\WaaSMedic*', ^
'\Microsoft\Windows\WindowsUpdate*', ^
'\Microsoft\WindowsUpdate*' ^
); ^
foreach ($path in $paths) { Get-ScheduledTask -TaskPath $path ^| Disable-ScheduledTask -ErrorAction SilentlyContinue }

echo Finished