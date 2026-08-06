param(
    [Parameter(Mandatory=$true)][string]$ProcessName,
    [switch]$CheckOnly
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
}
"@

$proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

if (-not $proc) {
    Write-Output "NOTFOUND:$ProcessName"
    exit 1
}

if ($CheckOnly) {
    Write-Output "FOUND:$($proc.MainWindowTitle)"
    exit 0
}

$hWnd = $proc.MainWindowHandle

if ([Win32Focus]::IsIconic($hWnd)) {
    [Win32Focus]::ShowWindow($hWnd, 9) | Out-Null  # SW_RESTORE
}

$fgWnd = [Win32Focus]::GetForegroundWindow()
[uint32]$fgThread = 0
[Win32Focus]::GetWindowThreadProcessId($fgWnd, [ref]$fgThread) | Out-Null
[uint32]$targetThread = 0
[Win32Focus]::GetWindowThreadProcessId($hWnd, [ref]$targetThread) | Out-Null
$curThread = [Win32Focus]::GetCurrentThreadId()

[Win32Focus]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
[Win32Focus]::AttachThreadInput($targetThread, $fgThread, $true) | Out-Null
[Win32Focus]::SetForegroundWindow($hWnd) | Out-Null
[Win32Focus]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
[Win32Focus]::AttachThreadInput($targetThread, $fgThread, $false) | Out-Null

Start-Sleep -Milliseconds 150
$nowFg = [Win32Focus]::GetForegroundWindow()
if ($nowFg -eq $hWnd) {
    Write-Output "OK:$($proc.MainWindowTitle)"
    exit 0
} else {
    Write-Output "FAILED:$($proc.MainWindowTitle)"
    exit 2
}
