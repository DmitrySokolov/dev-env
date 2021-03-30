Add-PackageInfo `
    -Name "Qt_Creator_ext_wininterrupt32" `
    -Description "Qt Creator extension: wininterrupt32 v{0}" `
    -Version "4.14.2" `
    -Platform "x86_64" `
    -Url "http://qt-mirror.dannhauer.de/online/qtsdkrepository/windows_x86/desktop/tools_qtcreator/qt.tools.qtcreator/4.14.2-0-202103191046wininterrupt32.7z" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "7_Zip", "Qt_Creator__4.14.2") `
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
