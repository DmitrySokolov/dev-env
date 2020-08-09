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
        if ($?) { (javac -version | Select-String '\b8\.0\.265\b' -Quiet) -eq $true } else { $? }
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Java8" ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJavaHome,FeatureOracleJavaSoft REMOVE=FeatureIcedTeaWeb,FeatureJNLPFileRunWith,FeatureJarFileRunWith /qb | Out-Default
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb | Out-Default
    }
