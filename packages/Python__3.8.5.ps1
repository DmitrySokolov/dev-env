Add-PackageInfo `
    -Name "Python" `
    -Description "Python v{0}" `
    -Version "3.8.5" `
    -Platform "x86_64" `
    -Url "https://www.python.org/ftp/python/3.8.5/python-3.8.5-amd64.exe" `
    -FileName "from_url" `
    -RequiresElevatedPS $true `
    -DependsOn @("Env_config__1.0") `
    -FindCmd {
        where.exe py 2>&1 | Out-Null
        if ($?) { (py -3 --version | Select-String '\b3\.8\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        & $Pkg.Installer /passive InstallAllUsers=1 TargetDir="$install_dir\Python3.8" PrependPath=1 CompileAll=1 Include_doc=0 Include_dev=0 Include_tcltk=0 Include_test=0 Include_launcher=1 InstallLauncherAllUsers=1
    } `
    -UninstallCmd {
        & $Pkg.Installer /uninstall /quiet
    }
