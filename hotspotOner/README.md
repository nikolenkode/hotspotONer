# Auto Hotspot for Windows 11

[Русская версия](README.ru.md)

Automatically turns on the Windows **Mobile Hotspot** when you sign in and keeps it on. No manual toggling, no passwords or settings to put into the script.

## Features

- Starts the hotspot at every sign-in, hidden, with no windows.
- Watchdog: checks every 30 seconds and turns the hotspot back on if it goes off.
- Waits for the network after boot, so it works even if the internet comes up late.
- Uses the SSID and password already configured in Windows. Nothing is stored in the script.
- One-click installer that registers a Task Scheduler job and restarts it on failure.
- Small log file for troubleshooting.

## Files

| File | Purpose |
|---|---|
| `install-hotspot.bat` | Installer: asks for admin rights, copies the script, creates the scheduled task, starts it |
| `Enable-Hotspot.ps1` | PowerShell script that turns on the hotspot and keeps checking it |

## Requirements

- Windows 10 or 11
- A Wi-Fi adapter that supports access point mode. Check with `netsh wlan show drivers` and look for `Hosted network supported : Yes`.
- An active internet connection (Ethernet or another Wi-Fi network). The hotspot shares an existing connection and cannot start without one.
- Administrator rights (installation only)

## Installation

1. Download or clone this repository.
2. Make sure `install-hotspot.bat` and `Enable-Hotspot.ps1` are in the **same folder**.
3. Double-click `install-hotspot.bat` and accept the UAC prompt.
4. Wait for `Done`.

The installer:

1. Requests administrator rights if needed.
2. Copies `Enable-Hotspot.ps1` to `C:\ProgramData\AutoHotspot`.
3. Creates the scheduled task `AutoHotspot` (trigger: at logon, highest privileges, restarts every minute on failure, runs on battery).
4. Starts the task immediately.

The SSID and password are the ones from **Settings → Network & internet → Mobile hotspot**. Windows generates defaults; change them there if you want your own. You can also turn off the *Power saving* option on that page so Windows does not switch the hotspot off when nobody is connected (the script would turn it back on anyway).

## How it works

The scheduled task launches `Enable-Hotspot.ps1`, which loops forever:

1. Get the current internet connection profile (`NetworkInformation.GetInternetConnectionProfile`).
2. If there is none yet, wait and check again.
3. Otherwise read the tethering state through `NetworkOperatorTetheringManager`.
4. If the hotspot is off, call `StartTetheringAsync()`.
5. Write the result to the log, sleep 30 seconds, repeat.

The hotspot API needs a user session, so the task starts at **sign-in**, not at boot. If you want the hotspot up without typing a password, enable auto sign-in (`netplwiz`). Keep in mind that this lowers the security of the PC.

## Configuration

Edit the top of `Enable-Hotspot.ps1`:

```powershell
$CheckIntervalSeconds = 30   # how often to check the hotspot state
```

After editing, run `install-hotspot.bat` again to copy the new version and restart the task.

## Logs

`C:\ProgramData\AutoHotspot\hotspot.log` (cleared automatically when it grows over 200 KB).

```
Watchdog started
No internet connection profile yet, waiting...
StartTethering: Success
```

Check the task state with:

```
schtasks /Query /TN "AutoHotspot"
```

## Stopping and uninstalling

While the task is installed, the hotspot comes back on within 30 seconds after you turn it off manually.

Stop temporarily (run as administrator), then turn the hotspot off in Windows settings:

```
schtasks /End /TN "AutoHotspot"
```

Remove completely:

```
schtasks /End /TN "AutoHotspot"
schtasks /Delete /TN "AutoHotspot" /F
rmdir /S /Q C:\ProgramData\AutoHotspot
```

## Security notes

- The hotspot is always on. Anyone with the password can use your internet connection, so use a strong password.
- The task runs with highest privileges. `C:\ProgramData\AutoHotspot` is not writable by standard users by default; do not loosen its permissions.
- The script makes no network requests and does not change hotspot settings. It only turns the hotspot on.
- Always-on hotspot drains laptop batteries faster and can lower speed if the internet comes through the same Wi-Fi adapter.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Hotspot never turns on, log says `No internet connection profile yet` | No active internet connection. Connect Ethernet or Wi-Fi. |
| Log shows a status other than `Success` | The adapter or driver may not support access point mode. Run `netsh wlan show drivers` and update the Wi-Fi driver. |
| No log file | The task did not run. Check it in Task Scheduler, column *Last Run Result*. |
| Works only when run manually | Make sure the task belongs to your user and that you sign in with that same account. |
| Installer says `Enable-Hotspot.ps1` not found | The two files are in different folders. |

## Limitations

Tested design only; behavior depends on your Wi-Fi adapter and driver. The legacy `netsh wlan hostednetwork` method is not used because it is unsupported on most Windows 11 adapters.

## License

Add a license of your choice (for example MIT) as `LICENSE`.