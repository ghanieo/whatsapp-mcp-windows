# Registers the "WhatsApp Bridge" scheduled task (current user, at logon, hidden, no password).
# Re-run to update it. Remove with: Unregister-ScheduledTask -TaskName 'WhatsApp Bridge' -Confirm:$false
$dir = $PSScriptRoot
$script = Join-Path $dir 'run-bridge.ps1'
$user = "$env:USERDOMAIN\$env:USERNAME"

# conhost --headless gives the bridge a console without showing a window
$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\conhost.exe" `
    -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`"" `
    -WorkingDirectory $dir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName 'WhatsApp Bridge' -Description 'Local WhatsApp bridge (whatsapp-mcp) for Claude; logs to bridge.log' `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Get-ScheduledTask -TaskName 'WhatsApp Bridge' | Select-Object TaskName, State
