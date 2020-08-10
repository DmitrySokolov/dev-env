Add-PackageInfo `
    -Name "JDK" `
    -Description "Java Development Kit v{0} (AdoptOpenJDK)" `
    -Version "8.0.265.01" `
    -Platform "x86_64" `
    -Url "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u265-b01/OpenJDK8U-jdk_x64_windows_hotspot_8u265b01.msi" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe javac 2>&1 | Out-Null
        if (-not $? -or (javac -version 2>&1 | Select-String '\b8\.0_265\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Java8" ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJavaHome,FeatureOracleJavaSoft REMOVE=FeatureIcedTeaWeb,FeatureJNLPFileRunWith,FeatureJarFileRunWith /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
