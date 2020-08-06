Add-PackageInfo `
    -Name "Perl" `
    -Description "Perl v{0}" `
    -Version "5.30.2.1" `
    -Platform "x86_64" `
    -Url "http://strawberryperl.com/download/5.30.2.1/strawberry-perl-5.30.2.1-64bit.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe py 2>&1 | Out-Null
        if ($?) { (perl --version | Select-String '\bv5\.30\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Perl" /qb
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb
    }
