Add-PackageInfo `
    -Name "Android_SDK" `
    -Description "Android SDK (API {0})" `
    -Version "29" `
    -Platform "x86_64" `
    -DependsOn @("Env_config", "Android_SDK_Manager") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable sdk_manager "$sdk_dir\cmdline-tools\latest\bin\sdkmanager.bat" -Scope 1
        Set-Variable build_tools_ver "29.0.3" -Scope 1
        Set-Variable sdk_ver "android-29" -Scope 1
    } `
    -FindCmd {
        Test-PathExists "$sdk_dir\platforms\$sdk_ver" -Type Container -Throw
    } `
    -InstallCmd {
        Write-Output yes `
            | & $sdk_manager `
                "build-tools;$build_tools_ver" `
                "platform-tools" `
                "platforms;$sdk_ver" `
                "extras;google;usb_driver" `
            | ForEach-Object {
                if ($_ -match '\]\s*(\d+)%') {
                    Write-CustomProgress -Activity 'Installing Android SDK' `
                        -Status ('{0}% Complete:' -f $Matches[1]) `
                        -PercentComplete $Matches[1]
                } else {
                    $_
                }
            } -End {
                Write-CustomProgress -Activity 'Installing Android SDK' -Completed
            }
        if (-not $?) { throw 'Error detected' }
        Set-EnvVar ANDROID_API_VERSION $sdk_ver Machine
        Set-EnvVar ANDROID_BUILD_TOOLS_VERSION $build_tools_ver Machine
    } `
    -UninstallCmd {
        if (Test-Path "$sdk_dir\platforms\$sdk_ver" -Type Container) {
            Remove-Path "$sdk_dir\platforms\$sdk_ver" -Recurse -Force
        }
        Remove-EnvVar ANDROID_API_VERSION Machine
        Remove-EnvVar ANDROID_BUILD_TOOLS_VERSION Machine
    }
