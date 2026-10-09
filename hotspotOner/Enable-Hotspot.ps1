# Enable-Hotspot.ps1
# Keeps the Windows Mobile Hotspot turned ON forever (watchdog loop).
# SSID / password are taken from: Settings -> Network & internet -> Mobile hotspot.

$CheckIntervalSeconds = 30
$LogFile = Join-Path $PSScriptRoot 'hotspot.log'

function Log($msg) {
    try {
        if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt 200KB) { Remove-Item $LogFile -Force }
        Add-Content -Path $LogFile -Value ("{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg)
    } catch {}
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
})[0]

function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

[Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime] | Out-Null
[Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime] | Out-Null

Log 'Watchdog started'

while ($true) {
    try {
        $conn = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()

        if ($null -eq $conn) {
            Log 'No internet connection profile yet, waiting...'
        }
        else {
            $manager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($conn)

            # 1 = On, 0 = Off
            if ($manager.TetheringOperationalState -ne 1) {
                $result = Await ($manager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
                Log ("StartTethering: {0} {1}" -f $result.Status, $result.AdditionalErrorMessage)
            }
        }
    }
    catch {
        Log ("Error: {0}" -f $_.Exception.Message)
    }
    Start-Sleep -Seconds $CheckIntervalSeconds
}