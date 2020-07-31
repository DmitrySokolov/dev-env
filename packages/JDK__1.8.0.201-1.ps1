Add-PackageInfo `
    -Name "JDK" `
    -Description "Java Development Kit v{0}" `
    -Version "1.8.0.201-1" `
    -Platform "x86_64" `
    -Url "https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.201-1/java-1.8.0-openjdk-1.8.0.201-1.b09.ojdkbuild.windows.x86_64.msi" `
    -FileName "from_url" `
    -RequiresElevatedPS $true `
    -DependsOn @("Env_config__1.0") `
    -FindCmd {
        where.exe javac 2>&1 | Out-Null ; $?
    } `
    -InstallCmd {
        msiexec.exe /i $Pkg.Installer INSTALLDIR="$install_dir\Java" ADDLOCAL=jdk_env_path,jdk_env_java_home /qb
    } `
    -UninstallCmd {
        msiexec.exe /x $Pkg.Installer /qb
    }
