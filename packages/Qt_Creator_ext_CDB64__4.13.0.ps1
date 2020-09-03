Add-PackageInfo `
    -Name "Qt_Creator_ext_CDB64" `
    -Description "Qt Creator extension: CDB 64-bit support v{0}" `
    -Version "4.13.0" `
    -Platform "x86_64" `
    -Url "https://mirrors.dotsrc.org/qtproject/online/qtsdkrepository/windows_x86/desktop/tools_qtcreator/qt.tools.qtcreatorcdbext/4.13.0-0qtcreatorcdbext64.7z" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "7_Zip", "Qt_Creator__4.13.0") `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Qt" -Scope 1
        Set-Variable qt_creator_dir "$root_dir\Tools\QtCreator" -Scope 1
        Set-Variable app_dir "$qt_creator_dir\lib\qtcreatorcdbext64" -Scope 1
    } `
    -FindCmd {
        throw 'Not found'
    } `
    -InstallCmd {
        if (Test-Path $app_dir -Type Container) { Remove-Item $app_dir -Recurse -Force }
        7z.exe x $Pkg.Installer -o"$root_dir" -bd -y | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        if (Test-Path $app_dir -Type Container) {
            Remove-Item $app_dir -Recurse -Force
            $parent_dir = Split-Path $app_dir
            if ($null -eq (Get-ChildItem $parent_dir)) { Remove-Item $parent_dir }
            if ($null -eq (Get-ChildItem $qt_creator_dir)) { Remove-Item $qt_creator_dir }
            if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        }
    }
