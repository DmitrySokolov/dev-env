Add-PackageInfo `
    -Name "Ninja" `
    -Description "Ninja build tool v{0}" `
    -Version "1.10.2" `
    -Platform "x86_64" `
    -Url "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe ninja 2>&1 | Out-Null
        if (-not $? -or (ninja --version | Select-String '\b1\.10\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        Expand-Archive -Path $Pkg.Installer -DestinationPath "$install_dir\Ninja"
        Set-EnvVar Path "$install_dir\Ninja" Machine
    } `
    -UninstallCmd {
        Remove-EnvVar Path "$install_dir\Ninja" Machine
        Remove-Item "$install_dir\Ninja" -Recurse -Force
    }
