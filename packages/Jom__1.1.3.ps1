Add-PackageInfo `
    -Name "Jom" `
    -Description "Jom build tool v{0}" `
    -Version "1.1.3" `
    -Platform "x86_64" `
    -Url "http://qt-mirror.dannhauer.de/official_releases/jom/jom_1_1_3.zip" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe jom 2>&1 | Out-Null
        if (-not $? -or (jom /version | Select-String '\b1\.1\.3\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        Expand-Archive -Path $Pkg.Installer -DestinationPath "$install_dir\Jom"
        Set-EnvVar Path "$install_dir\Jom" Machine
    } `
    -UninstallCmd {
        Remove-EnvVar Path "$install_dir\Jom" Machine
        Remove-Item "$install_dir\Jom" -Recurse -Force
    }
