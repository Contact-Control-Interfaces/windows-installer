# Contact CI for Windows

The installer for Contact CI software on 64-bit Windows. One file, `ContactCiInstaller.exe`, from this repository's [releases](https://github.com/Contact-Control-Interfaces/windows-installer/releases), installs:

| Component | What it is |
| -- | -- |
| Contact CI Service | A background Windows service that owns the gloves connected over USB or Bluetooth. |
| Contact CI Manager | A desktop application that shows the Service, gloves and connected applications. |
| .NET Framework 4.8 | Needed by the Service. Installed only on a machine that does not already have .NET Framework 4.8 or later. |

For Linux, see [linux-installer](https://github.com/Contact-Control-Interfaces/linux-installer).

## Install

1. Download `ContactCiInstaller.exe` from the newest [release](https://github.com/Contact-Control-Interfaces/windows-installer/releases).
2. Run it, accept the licence agreement, and approve the Windows prompt for administrator rights.

The software installs under `C:\Program Files\Contact CI`. The Service is registered as `ContactCiService` and started, and the Manager is added to the Start menu.

To upgrade, run a newer `ContactCiInstaller.exe`: it replaces the installed version.

### Without the windows

For a scripted install, from an elevated prompt:

```powershell
.\ContactCiInstaller.exe /quiet /norestart
```

`/passive` shows progress and asks nothing. `/log <file>` writes the installer's log to a file of your choice.

## Check that it works

Open **Contact CI Manager** from the Start menu: it shows whether the Service is running and which gloves are connected. From PowerShell:

```powershell
Get-Service ContactCiService
```

The Service writes its logs to `%ProgramData%\Contact CI\Service\Logs`.

## Remove

In Windows Settings, open **Apps**, find **Contact CI** and choose **Uninstall**. Or, from an elevated prompt, with the same `ContactCiInstaller.exe` that installed it:

```powershell
.\ContactCiInstaller.exe /uninstall /quiet /norestart
```

This removes the Service and the Manager. The .NET Framework stays, as other software may depend on it.

## Licence and support

The software is proprietary and distributed under the Contact CI End User License Agreement, which the installer shows before it installs anything. See [LICENSE.md](LICENSE.md).

Questions and problems: support@contactci.co.

Security problems: see [SECURITY.md](SECURITY.md).

## For maintainers

The installer is a [WiX Toolset v3](https://github.com/wixtoolset/wix3/releases) bundle. It builds nothing from source: it wraps installers that other repositories produce.

| Path | What it is |
| -- | -- |
| [`InstallerBootstrapper/Bundle.wxs`](InstallerBootstrapper/Bundle.wxs) | The bundle: its version, and the packages it installs, in order. |
| `ContactCiServiceInstaller.msi` | The Service's installer, from `windows-service`. |
| `ContactCiManagerInstaller.msi` | The Manager's installer, from `manager`. |
| [`InstallerBootstrapper/license.rtf`](InstallerBootstrapper/license.rtf) | The licence agreement the installer shows. |
| [`build.ps1`](build.ps1) | Builds `ContactCiInstaller.exe`. |
| [`tools/verify-install.ps1`](tools/verify-install.ps1) | Installs and removes a built installer, and checks both. |

### Build

Install WiX Toolset v3 (3.11 or later), then:

```powershell
.\build.ps1
```

The result is `InstallerBootstrapper\bin\Release\ContactCiInstaller.exe`. On its first run the script downloads Microsoft's .NET Framework 4.8 offline installer to the repository root, and it refuses a file that does not match the pinned SHA-256 or is not signed by Microsoft.

`Installer.sln` builds the same bundle in Visual Studio or Rider with the WiX v3 extension. Run `build.ps1` once first, so that the .NET Framework installer is in place.

### Test

```powershell
.\tools\verify-install.ps1
```

This installs the built installer silently, checks that the Service and the Manager are installed and that `ContactCiService` is registered, removes it again and checks that nothing is left. It needs an elevated prompt and it changes the machine, so use a virtual machine, not the computer you work on. It refuses to run where Contact CI software is already installed.

The [`build` workflow](.github/workflows/build.yml) runs the build and this test on every pull request and on every push to `main`. It signs nothing and publishes nothing.

### Release

A release is built and signed by hand, because signing needs the company's code signing certificate. A maintainer who holds it does this:

1. In a pull request, replace the two `.msi` files with the signed versions to ship, and set `Version` in `Bundle.wxs`. Versions follow `X.Y.Z`; a tag is `vX.Y.Z`.
2. After it merges, build `main` with `build.ps1`.
3. Sign the installer. A WiX bundle is signed in two steps, the engine inside it first and then the bundle. With `insignia.exe` from WiX and `signtool.exe` from the Windows SDK:

   ```powershell
   cd InstallerBootstrapper\bin\Release
   insignia -ib ContactCiInstaller.exe -o engine.exe
   signtool sign <certificate options> engine.exe
   insignia -ab engine.exe ContactCiInstaller.exe -o ContactCiInstaller.exe
   signtool sign <certificate options> ContactCiInstaller.exe
   ```

4. Tag the commit `vX.Y.Z`, create the GitHub release for that tag, and attach the signed `ContactCiInstaller.exe`. In the release notes, name the Service and Manager versions inside.

Tags and versions are permanent: a broken release is fixed by the next patch version.
