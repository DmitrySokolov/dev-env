Add-PackageInfo `
    -Name "Perl" `
    -Description "Perl v{0}" `
    -Version "5.32.1.1" `
    -Platform "x86_64" `
    -Url "https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe py 2>&1 | Out-Null
        if (-not $? -or (perl --version | Select-String '\bv5\.32\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Perl" /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
