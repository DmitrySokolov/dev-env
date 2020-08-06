Add-PackageInfo `
    -Name "TortoiseHg" `
    -Description "Mercurial VCS bundled with TortoiseHg (GUI) v{0}" `
    -Version "5.5" `
    -Platform "x86_64" `
    -Url "https://www.mercurial-scm.org/release/tortoisehg/windows/tortoisehg-stable-5.5.102.119-x64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe thg 2>&1 | Out-Null
        if ($?) { (thg version | Select-String '\b5\.5\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\TortoiseHg" ADDLOCAL=Complete /qb
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb
    }
