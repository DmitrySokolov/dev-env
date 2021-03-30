Add-PackageInfo `
    -Name "Qt_Creator" `
    -Description "Qt Creator v{0}" `
    -Version "4.14.2" `
    -Platform "x86_64" `
    -Url "http://qt-mirror.dannhauer.de/online/qtsdkrepository/windows_x86/desktop/tools_qtcreator/qt.tools.qtcreator/4.14.2-0-202103191046qtcreator.7z" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "7_Zip") `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Qt" -Scope 1
        Set-Variable app_dir "$root_dir\Tools\QtCreator" -Scope 1
        Set-Variable app "$app_dir\bin\qtcreator.exe" -Scope 1
        Set-Variable shortcuts_dir "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Qt" -Scope 1
        Set-Variable app_shortcut "$shortcuts_dir\Qt Creator.lnk" -Scope 1
    } `
    -FindCmd {
        Test-PathExists $app -Throw
        if ('4.14.2' -ne [System.Diagnostics.FileVersionInfo]::GetVersionInfo($app).FileVersion) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        if (Test-Path $app_dir -Type Container) { Remove-Item $app_dir -Recurse -Force }
        7z.exe x $Pkg.Installer -o"$root_dir" -bd -y | Out-Default
        if (-not $?) { throw 'Error detected' }
        New-FileShortcut $app_shortcut -TargetPath "$app_dir\bin\qtcreator.exe" -Description "Qt Creator v$($Pkg.Veresion)" -WorkingDir "$app_dir\bin"
    } `
    -UninstallCmd {
        if (Test-Path $app_dir -Type Container) {
            Remove-Item $app_dir -Recurse -Force
            $parent_dir = Split-Path $app_dir
            if ($null -eq (Get-ChildItem $parent_dir)) { Remove-Item $parent_dir }
            if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        }
        if (Test-Path $app_shortcut) {
            Remove-Item $app_shortcut
            if ($null -eq (Get-ChildItem $shortcuts_dir)) { Remove-Item $shortcuts_dir }
        }
    }
