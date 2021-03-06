Add-PackageInfo `
    -Name "TortoiseHg" `
    -Description "Mercurial VCS bundled with TortoiseHg (GUI) v{0}" `
    -Version "5.5.1" `
    -Platform "x86_64" `
    -Url "https://www.mercurial-scm.org/release/tortoisehg/windows/tortoisehg-5.5.1-x64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe thg 2>&1 | Out-Null
        if (-not $? -or (thg version | Select-String '\b5\.5\.1\D' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\TortoiseHg" ADDLOCAL=Complete /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
