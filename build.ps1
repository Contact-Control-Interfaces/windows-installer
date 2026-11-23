<#
.SYNOPSIS
    Builds ContactCiInstaller.exe, the bundled installer.

.DESCRIPTION
    Compiles InstallerBootstrapper\Bundle.wxs with WiX Toolset v3 into
    InstallerBootstrapper\bin\Release\ContactCiInstaller.exe: the same output,
    in the same place, as building Installer.sln.

    The bundle wraps three files that sit in the repository root:

      ContactCiServiceInstaller.msi    committed
      ContactCiManagerInstaller.msi    committed
      ndp48-x86-x64-allos-enu.exe      Microsoft's .NET Framework 4.8 offline
                                       installer; downloaded here when missing

    The .NET Framework installer must match the SHA-256 pinned below and carry
    a valid Microsoft signature, whether it was just downloaded or was already
    there.

    Nothing is signed. See "Release" in README.md.

    Needs WiX Toolset v3 (3.11 or later): https://github.com/wixtoolset/wix3/releases

.EXAMPLE
    .\build.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is far slower with its progress bar

$root    = $PSScriptRoot
$project = Join-Path $root 'InstallerBootstrapper'

$net48       = Join-Path $root 'ndp48-x86-x64-allos-enu.exe'
$net48Url    = 'https://go.microsoft.com/fwlink/?linkid=2088631'
$net48Sha256 = '0A3A390C47E639D0F7FC65B21195FEE6B7F65B066F80F70C60FAB191D14B7E40'

function Write-Step([string]$text) { Write-Host "== $text" }

# The directory holding candle.exe and light.exe. The WiX installer sets WIX;
# failing that, look where it installs.
function Find-Wix {
    $candidates = @()
    if ($env:WIX) { $candidates += Join-Path $env:WIX 'bin' }
    $candidates += Get-ChildItem -Path ${env:ProgramFiles(x86)} -Directory -Filter 'WiX Toolset v3*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'bin' }
    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate 'candle.exe')) { return $candidate }
    }
    throw 'WiX Toolset v3 was not found. Install it from https://github.com/wixtoolset/wix3/releases and run this again.'
}

function Invoke-Tool([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "$(Split-Path $exe -Leaf) failed with exit code $LASTEXITCODE." }
}

# --- What the bundle wraps ---------------------------------------------------
foreach ($msi in 'ContactCiServiceInstaller.msi', 'ContactCiManagerInstaller.msi') {
    if (-not (Test-Path (Join-Path $root $msi))) { throw "$msi is missing from the repository root." }
}

if (-not (Test-Path $net48)) {
    Write-Step 'Downloading the .NET Framework 4.8 offline installer'
    $partial = "$net48.partial"
    Invoke-WebRequest -Uri $net48Url -OutFile $partial -UseBasicParsing
    Move-Item -Path $partial -Destination $net48 -Force
}

Write-Step 'Checking the .NET Framework 4.8 offline installer'
$hash = (Get-FileHash -Path $net48 -Algorithm SHA256).Hash
if ($hash -ne $net48Sha256) {
    throw "$(Split-Path $net48 -Leaf) has SHA-256 $hash, not the pinned $net48Sha256. Delete it and run this again; if Microsoft has replaced the file, check the new one before changing the pin."
}
$signature = Get-AuthenticodeSignature -FilePath $net48
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
    throw "$(Split-Path $net48 -Leaf) is not validly signed by Microsoft (status: $($signature.Status))."
}

# --- Build -------------------------------------------------------------------
$wix = Find-Wix
[xml]$bundle = Get-Content -Path (Join-Path $project 'Bundle.wxs') -Raw
$version = $bundle.Wix.Bundle.Version
Write-Step "Building version $version with WiX at $wix"

$extensions = '-ext', 'WixUtilExtension', '-ext', 'WixBalExtension'
$output = 'bin\Release\ContactCiInstaller.exe'

# From the project directory: Bundle.wxs names its files relative to it.
Push-Location $project
try {
    New-Item -ItemType Directory -Path 'obj\Release', 'bin\Release' -Force | Out-Null
    Invoke-Tool (Join-Path $wix 'candle.exe') (@('-nologo', '-arch', 'x86') + $extensions + @('-out', 'obj\Release\', 'Bundle.wxs'))
    Invoke-Tool (Join-Path $wix 'light.exe')  (@('-nologo') + $extensions + @('-out', $output, 'obj\Release\Bundle.wixobj'))
}
finally {
    Pop-Location
}

$built = Get-Item (Join-Path $project $output)
Write-Step 'Built'
Write-Host ("{0}`n  version  {1}`n  size     {2:N0} bytes`n  SHA-256  {3}`n  unsigned" -f `
    $built.FullName, $version, $built.Length, (Get-FileHash -Path $built.FullName -Algorithm SHA256).Hash)
