# Installer

This is the bundled installer for Contact CI software.

In currently bundles:
- An offline installer for the .NET framework version 4.8
- The Windows Service installer ([see the repo here](https://gitlab.contact.ci/windows/windows-service))
- The Manager installer ([see Manager repo here])(https://gitlab.contact.ci/tools/manager) and ([see Manager Installer repo here])(https://gitlab.contact.ci/windows/managerinstaller)

The installer uses WiX toolkit v3.

## Building

You can build the installer by running msbuild, or just build in Rider or Visual Studio. This should result in a `ContactCiInstaller.exe` in `/bin/Release/`.

## Sign and Publish

**To sign and publish the installer, you need access to the code signing certificate private key. Currently, only John has this, so bug him (john@contactci.co).**

- Copy the msi for the Windows Service into the root of the repository. Ensure you copy the correct version that you're intending on bundling/releasing.
- Copy the msi for the Manager into the root of the repository. Ensure you copy the correct version that you're intending on bundling/releasing.
- Run `sign_installer.bat` (John, for when you inevitably forget, you put this in your Tools directory).
