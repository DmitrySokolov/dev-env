Add-PackageInfo `
    -Name "Qt_Creator_ext_CDB" `
    -Description "Qt Creator extension: CDB support v{0}" `
    -Version "4.12.4" `
    -Platform "x86_64" `
    -Url "http://qt-mirror.dannhauer.de/official_releases/qtcreator/4.12/4.12.4/installer_source/windows_msvc2017_x64/qtcreatorcdbext.7z" `
    -FileName "qtcreatorcdbext_4.12.4.7z" `
    -DependsOn @("Env_config", "7_Zip", "Qt_Creator__4.12.4") `
    -InitCmd {
        Set-Variable $root_dir "$install_dir\Qt" -Scope 1
        Set-Variable $qt_creator_dir "$install_dir\Qt\QtCreator" -Scope 1
        Set-Variable $app_dir "$install_dir\Qt\QtCreator\lib\qtcreatorcdbext64" -Scope 1
        Set-Variable $app "$install_dir\Qt\QtCreator\lib\qtcreatorcdbext64\qtcreatorcdbext.dll" -Scope 1
    } `
    -FindCmd {
        $false
    } `
    -InstallCmd {
        if (Test-Path $app_dir -Type Container) { Remove-Item $app_dir -Recurse -Force }
        7z.exe x $Pkg.Installer -o"$qt_creator_dir" -bd -y | Out-Default
    } `
    -UninstallCmd {
        if (Test-Path $app_dir -Type Container) {
            Remove-Item $app_dir -Recurse -Force
            if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        }
    }
