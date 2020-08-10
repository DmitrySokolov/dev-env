Add-PackageInfo `
    -Name "JDK" `
    -Description "Java Development Kit v{0} (ojdkbuild)" `
    -Version "1.8.0.201-1" `
    -Platform "x86_64" `
    -Url "https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.201-1/java-1.8.0-openjdk-1.8.0.201-1.b09.ojdkbuild.windows.x86_64.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        if (-not $? -or (javac -version 2>&1 | Select-String '\b8\.0_201\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Java8" ADDLOCAL=jdk_env_path,jdk_env_java_home /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
