Add-PackageInfo `
    -Name "Android_SDK_Manager" `
    -Description "Android SDK Manager ({0})" `
    -Version "6609375" `
    -Platform "x86_64" `
    -Url "https://dl.google.com/android/repository/commandlinetools-win-6609375_latest.zip" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "JDK__8") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable sdk_cmdlinetools_dir "$sdk_dir\cmdline-tools" -Scope 1
        Set-Variable sdk_manager_dir "$sdk_dir\cmdline-tools\latest" -Scope 1
        Set-Variable sdk_manager "$sdk_dir\cmdline-tools\latest\bin\sdkmanager.bat" -Scope 1
    } `
    -FindCmd {
        Test-PathExists $sdk_manager -Throw
    } `
    -InstallCmd {
        if (Test-Path $sdk_cmdlinetools_dir -Type Container) {
            Remove-Item $sdk_cmdlinetools_dir -Recurse -Force
        }
        Expand-Archive -Path $Pkg.Installer -DestinationPath $sdk_cmdlinetools_dir
        Move-Item "$sdk_cmdlinetools_dir\tools" $sdk_manager_dir
        Set-EnvVar ANDROID_SDK_ROOT $sdk_dir Machine
    } `
    -UninstallCmd {
        Remove-Item $sdk_cmdlinetools_dir -Recurse -Force
    }
