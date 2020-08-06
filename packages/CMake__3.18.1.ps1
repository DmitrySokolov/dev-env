Add-PackageInfo `
    -Name "CMake" `
    -Description "CMake v{0}" `
    -Version "3.18.1" `
    -Platform "x86_64" `
    -Url "https://github.com/Kitware/CMake/releases/download/v3.18.1/cmake-3.18.1-win64-x64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe cmake 2>&1 | Out-Null
        if ($?) { (cmake --version | Select-String '\b3\.18\.1\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\CMake" ADD_CMAKE_TO_PATH=System /qb
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb
    }
