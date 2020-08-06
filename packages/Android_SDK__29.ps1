Add-PackageInfo `
    -Name "Android_SDK" `
    -Description "Android SDK (API {0})" `
    -Version "29" `
    -Platform "x86_64" `
    -Url "https://dl.google.com/android/repository/commandlinetools-win-6609375_latest.zip" `
    -FileName "from_url" `
    -DependsOn @("Env_config__1.0") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable sdk_manager "$sdk_dir\cmdline-tools\latest\bin\sdkmanager" -Scope 1
        Set-Variable build_tools_ver "29.0.3" -Scope 1
        Set-Variable sdk_ver "android-29" -Scope 1
        Set-Variable ndk_ver "21.0.6113669" -Scope 1
    } `
    -FindCmd {
        Test-EnvVar ANDROID_SDK_ROOT isDir
    } `
    -InstallCmd {
        if (Test-Path "$sdk_dir\cmdline-tools" -Type Container) {
            Remove-Item "$sdk_dir\cmdline-tools" -Recurse -Force
        }
        Expand-Archive -Path $Pkg.Installer -DestinationPath "$sdk_dir\cmdline-tools"
        Move-Item "$sdk_dir\cmdline-tools\tools" "$sdk_dir\cmdline-tools\latest"
        Write-Output yes `
            | & $sdk_manager `
                "build-tools;$build_tools_ver" `
                "platform-tools" `
                "platforms;$sdk_ver" `
                "ndk;$ndk_ver" `
            | ForEach-Object {
                if ($_ -match '\]\s*(\d+)%') {
                    Write-Progress 'Installing Android SDK' `
                        -Status ('{0}% Complete:' -f $Matches[1]) `
                        -PercentComplete $Matches[1]
                } else {
                    $_
                }
            } -End {
                Write-Progress 'Installing Android SDK' -Completed
            }
        Set-EnvVar ANDROID_SDK_ROOT $sdk_dir
        Set-EnvVar ANDROID_NDK_ROOT "$sdk_dir\ndk\$ndk_ver"
        Set-EnvVar ANDROID_NDK_HOST "windows-x86_64"
        Set-EnvVar ANDROID_API_VERSION $sdk_ver
        Set-EnvVar ANDROID_BUILD_TOOLS_VERSION $build_tools_ver
    } `
    -UninstallCmd {
        Remove-Item $sdk_dir -Recurse -Force
        if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        Remove-EnvVar ANDROID_SDK_ROOT
        Remove-EnvVar ANDROID_NDK_ROOT
        Remove-EnvVar ANDROID_NDK_HOST
        Remove-EnvVar ANDROID_API_VERSION
        Remove-EnvVar ANDROID_BUILD_TOOLS_VERSION
    }
