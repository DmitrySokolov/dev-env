Add-PackageInfo `
    -Name "Qt_Creator_ext_sdktool" `
    -Description "Qt Creator extension: sdktool v{0}" `
    -Version "4.12.4" `
    -Platform "x86_64" `
    -Url "https://mirrors.dotsrc.org/qtproject/online/qtsdkrepository/windows_x86/desktop/tools_qtcreator/qt.tools.qtcreator/4.12.4-0qtcreator_sdktool.7z" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "7_Zip", "Qt_Creator__4.12.4") `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Qt" -Scope 1
    } `
    -FindCmd {
        throw 'Not found'
    } `
    -InstallCmd {
        7z.exe x $Pkg.Installer -o"$root_dir" -bd -y | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
