<#
.SYNOPSIS
    Installs a built ContactCiInstaller.exe, checks what it installed, removes
    it and checks that nothing is left.

.DESCRIPTION
    Runs the installer the way a scripted install does (/quiet /norestart),
    then checks what a user relies on:

      1. Windows lists Contact CI, the Contact CI Service and the Contact CI
         Manager as installed;
      2. the service ContactCiService is registered;
      3. after /uninstall, none of the three is listed and the service is gone.

    Whether the service is running is reported, not required: on a GitHub
    runner it is registered but does not stay running.

    It installs and removes software on this machine, so it needs an elevated
    prompt and belongs on a CI runner or a virtual machine. It refuses to run
    where Contact CI software is already installed, as it would remove it.

.PARAMETER Installer
    The installer to test. Defaults to what build.ps1 produces.

.PARAMETER LogDirectory
    Where the installer's logs are written.

.EXAMPLE
    .\tools\verify-install.ps1
#>
[CmdletBinding()]
param(
    [string]$Installer = (Join-Path $PSScriptRoot '..\InstallerBootstrapper\bin\Release\ContactCiInstaller.exe'),
    [string]$LogDirectory = (Join-Path ([IO.Path]::GetTempPath()) 'contactci-installer-logs')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$products    = 'Contact CI', 'Contact CI Service', 'Contact CI Manager'
$serviceName = 'ContactCiService'

function Write-Step([string]$text) { Write-Host "== $text" }

# The entries Windows lists under installed apps whose name is one of ours.
# The bundle registers as a 32-bit program, the two MSIs as 64-bit ones.
function Get-Installed {
    $roots = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
             'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.PSObject.Properties['DisplayName'] -and $products -contains $_.DisplayName } |
        ForEach-Object {
            $displayVersion = if ($_.PSObject.Properties['DisplayVersion']) { $_.DisplayVersion } else { '' }
            [pscustomobject]@{ Name = $_.DisplayName; Version = $displayVersion }
        }
}

# Runs the installer with the given switches and waits for it. 3010 is
# success with a restart pending.
function Invoke-Installer([string[]]$switches, [string]$log) {
    $arguments = $switches + @('/quiet', '/norestart', '/log', "`"$log`"")
    $process = Start-Process -FilePath $Installer -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -notin 0, 3010) {
        throw "The installer exited with code $($process.ExitCode). Its log is $log."
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$elevated = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $elevated) { throw 'Run this from an elevated prompt: it installs and removes software.' }

if (-not (Test-Path $Installer)) { throw "$Installer was not found. Run build.ps1 first." }
$Installer = (Resolve-Path $Installer).Path

$present = @(Get-Installed)
if ($present.Count -gt 0 -or (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
    throw 'Contact CI software is already installed on this machine. This test would remove it; run it on a clean machine.'
}

New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null

# --- Install -----------------------------------------------------------------
# Whatever the checks find, the installer is removed again afterwards, so a
# failed run does not leave the machine with software the next run trips over.
$checked = $false
try {
    Write-Step "Installing $Installer"
    Invoke-Installer @() (Join-Path $LogDirectory 'install.log')

    $installed = @(Get-Installed)
    $installed | Sort-Object Name | Format-Table -AutoSize | Out-String | Write-Host
    $names = @($installed | ForEach-Object { $_.Name })
    foreach ($product in $products) {
        if ($names -notcontains $product) { throw "'$product' is not listed as installed." }
    }

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) { throw "The service $serviceName is not registered." }
    for ($i = 0; $i -lt 20 -and $service.Status -ne 'Running'; $i++) {
        Start-Sleep -Milliseconds 500
        $service.Refresh()
    }
    Write-Host "$serviceName is registered; status: $($service.Status)."
    if ($service.Status -ne 'Running') {
        Write-Warning "$serviceName is not running. This test does not require it to be; see the Service's log if that is unexpected on this machine."
    }
    $checked = $true
}
finally {
    # --- Remove --------------------------------------------------------------
    Write-Step 'Removing it'
    try {
        Invoke-Installer @('/uninstall') (Join-Path $LogDirectory 'uninstall.log')
    }
    catch {
        # A failed check above is the error to report; don't replace it.
        if ($checked) { throw }
        Write-Warning "Removal failed as well: $_"
    }
}

$left = @(Get-Installed)
if ($left.Count -gt 0) { throw "Still listed as installed after removal: $(@($left | ForEach-Object { $_.Name }) -join ', ')." }
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    throw "The service $serviceName is still registered after removal."
}

Write-Step 'Installed and removed cleanly'
