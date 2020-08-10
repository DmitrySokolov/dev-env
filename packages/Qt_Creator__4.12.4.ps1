Add-PackageInfo `
    -Name "Qt_Creator" `
    -Description "Qt Creator v{0}" `
    -Version "4.12.4" `
    -Platform "x86_64" `
    -Url "http://qt-mirror.dannhauer.de/official_releases/qtcreator/4.12/4.12.4/installer_source/windows_msvc2017_x64/qtcreator.7z" `
    -FileName "qtcreator_4.12.4.7z" `
    -DependsOn @("Env_config", "7_Zip") `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Qt" -Scope 1
        Set-Variable app_dir "$install_dir\Qt\QtCreator" -Scope 1
        Set-Variable app "$install_dir\Qt\QtCreator\bin\qtcreator.exe" -Scope 1
        Set-Variable shortcuts_dir "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Qt" -Scope 1
        Set-Variable app_shortcut "$shortcuts_dir\Qt Creator.lnk" -Scope 1
    } `
    -FindCmd {
        Test-PathExists $app -Throw
        if ('4.12.4' -ne [System.Diagnostics.FileVersionInfo]::GetVersionInfo($app).FileVersion) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        if (Test-Path $app_dir -Type Container) { Remove-Item $app_dir -Recurse -Force }
        7z.exe x $Pkg.Installer -o"$app_dir" -bd -y | Out-Default
        if (-not $?) { throw 'Error detected' }
        New-FileShortcut $app_shortcut -TargetPath "$app_dir\bin\qtcreator.exe" -Description "Qt Creator v$($Pkg.Veresion)" -WorkingDir "$app_dir\bin"
    } `
    -UninstallCmd {
        if (Test-Path $app_dir -Type Container) {
            Remove-Item $app_dir -Recurse -Force
            if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        }
        if (Test-Path $app_shortcut) {
            Remove-Item $app_shortcut
            if ($null -eq (Get-ChildItem $shortcuts_dir)) { Remove-Item $shortcuts_dir }
        }
    }
