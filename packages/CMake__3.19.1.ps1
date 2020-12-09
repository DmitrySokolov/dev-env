Add-PackageInfo `
    -Name "CMake" `
    -Description "CMake v{0}" `
    -Version "3.19.1" `
    -Platform "x86_64" `
    -Url "https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-win64-x64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe cmake 2>&1 | Out-Null
        if (-not $? -or (cmake --version | Select-String '\b3\.19\.1\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\CMake" ADD_CMAKE_TO_PATH=System /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
