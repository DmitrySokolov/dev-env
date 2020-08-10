Add-PackageInfo `
    -Name "7_Zip" `
    -Description "7-Zip v{0}" `
    -Version "19.0" `
    -Platform "x86_64" `
    -Url "https://www.7-zip.org/a/7z1900-x64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        $app = '7z.exe'
        where.exe $app 2>&1 | Out-Null
        if (-not $?) {
            $app = "$env:ProgramFiles\7-Zip\7z.exe"
            if (-not (Test-Path $app)) { $app = "$install_dir\7-Zip\7z.exe" }
            if (-not (Test-Path $app)) { throw 'Not found' }
        }
        if ((& $app | Select-String '\b19\.00\b' -Quiet) -eq $true) {
            if ($app -ne '7z.exe') {
                Set-EnvVar Path (Split-Path $app) Machine
            }
        } else {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\7-Zip" /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
        Set-EnvVar Path "$install_dir\7-Zip" Machine
    } `
    -UninstallCmd {
        Remove-EnvVar Path (Split-Path (where.exe 7z.exe)) Machine
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
