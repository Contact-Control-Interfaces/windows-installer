# Installer

This is the bundled installer for Contact CI software.

In currently bundles:
- An offline installer for the .NET framework version 4.8
- The Windows Service installer ([see the repo here](https://gitlab.contact.ci/windows/windows-service))

The installer uses WiX toolkit v3.

## Building

You can build the installer by running msbuild, or just build in Rider or Visual Studio. This should result in a `ContactCiInstaller.exe` in `/bin/Release/`.

## Sign and Publish

**To sign and publish the installer, you need access to the code signing certificate private key. Currently, only John has this, so bug him (john@contactci.co).**

- Copy the msi for the Windows Service into the root of the repository. Ensure you copy the correct version that you're intending on bundling/releasing.
- Run `publish.bat`, enter code signing certificate authentication when prompted, and at the end enter the version number for the release.

### Setup for Sign and Publish

You'll need to have the path to your wix install binaries in your PATH. This is for the `insignia` tool used to extract and repatch the installer engine executable. Mine looks like `C:\Program Files (x86)\WiX Toolset v3.11\bin\`

You'll need to have the path to your Windows SDK (Windows Kit? whatever it's called) in your PATH. Mine looks like `C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86`

You'll need to have the gitlab CLI installed. [Get it here](https://gitlab.com/gitlab-org/cli)

#### Gitlab CLI Setup

You'll need to authenticate with our Gitlab instance in order to upload a release artifact. To do this, generate a personal access token by going to https://gitlab.contact.ci/-/profile/personal_access_tokens.

- Run `glab config set --global host gitlab.contact.ci`
- Run `glab config set --global token [YOUR TOKEN HERE]`

