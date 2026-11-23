# Security

## Reporting a vulnerability

Please do not open a public issue or pull request for a security problem.

Report it privately through GitHub: on this repository's **Security** tab, choose [**Report a vulnerability**](https://github.com/Contact-Control-Interfaces/windows-installer/security/advisories/new). Only the maintainers and you can see the report.

If you cannot use GitHub, write to support@contactci.co and ask for a private channel. Leave the details out of that first message.

## What to report here

This repository is the public home of Contact CI software for Windows, so report here any problem in:

- the installer, `ContactCiInstaller.exe`;
- the Contact CI Service or the Contact CI Manager that it installs;
- this repository's build script, test script or workflow.

## What helps

- The installer's version (in Windows Settings, under **Apps**, the version shown for **Contact CI**) and your Windows version.
- What an attacker gains: for example administrator rights, code running as another user, or reading data they should not see.
- The smallest set of steps that shows the problem.
- Whether it needs a glove connected, and whether it needs administrator rights to begin with.

A maintainer replies on the report. Please keep the details there until a fixed version is released.

## Checking a download

Download `ContactCiInstaller.exe` only from this repository's [releases](https://github.com/Contact-Control-Interfaces/windows-installer/releases). A released installer carries Contact CI's digital signature: in the file's **Properties**, the **Digital Signatures** tab lists it, and Windows names the publisher when it asks for administrator rights. Do not run an installer that has no signature or names another publisher.
