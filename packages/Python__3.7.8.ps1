Add-PackageInfo `
    -Name "Python" `
    -Description "Python v{0}" `
    -Version "3.7.8" `
    -Platform "x86_64" `
    -Url "https://www.python.org/ftp/python/3.7.8/python-3.7.8-amd64.exe" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe py 2>&1 | Out-Null
        if ($?) { (py -3 --version | Select-String '\b3\.7\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        & $Pkg.Installer /passive InstallAllUsers=1 TargetDir="$install_dir\Python3.7" PrependPath=1 CompileAll=1 Include_doc=0 Include_dev=0 Include_tcltk=0 Include_test=0 Include_launcher=1 InstallLauncherAllUsers=1 | Out-Default
    } `
    -UninstallCmd {
        & $Pkg.Installer /uninstall /quiet | Out-Default
    }
