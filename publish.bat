set certificateThumbprint=167f0be1b06ec61d12178859b3ec8488f7175105

pushd .

:: -- Sign the bootstrap installer bundle --
cd .\InstallerBootstrapper\bin\Release\

:: Extract bootstrap engine executable
insignia.exe -ib ContactCiInstaller.exe -o engine.exe || exit /b 1

:: Sign the extracted engine.exe
signtool.exe sign /d "Contact CI" /fd sha256 /tr http://ts.ssl.com /td sha256 /sha1 %certificateThumbprint% engine.exe || exit /b 1

:: Slam it back into the bootstrap installer bundle
insignia.exe -ab engine.exe ContactCiInstaller.exe -o ContactCiInstaller.exe || exit /b 1

:: Clean up temporary engine executable
del engine.exe

:: Sign the bundle itself
signtool.exe sign /d "Contact CI" /fd sha256 /tr http://ts.ssl.com /td sha256 /sha1 %certificateThumbprint% ContactCiInstaller.exe || exit /b 1

set /p "version=Enter version: "

glab release --repo "windows/installer" create %version% ./ContactCiInstaller.exe

popd