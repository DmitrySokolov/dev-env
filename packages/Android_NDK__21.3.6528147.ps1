Add-PackageInfo `
    -Name "Android_NDK" `
    -Description "Android NDK {0}" `
    -Version "21.3.6528147" `
    -Platform "x86_64" `
    -DependsOn @("Env_config", "Android_SDK_Manager") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable ndk_ver "21.3.6528147" -Scope 1
        Set-Variable ndk_dir "$sdk_dir\ndk\$ndk_ver" -Scope 1
        Set-Variable sdk_manager "$sdk_dir\cmdline-tools\latest\bin\sdkmanager" -Scope 1
    } `
    -FindCmd {
        Test-PathExists "$ndk_dir" -Type Container -Throw
    } `
    -InstallCmd {
        & $sdk_manager `
                "ndk;$ndk_ver" `
                "extras;google;usb_driver" `
            | ForEach-Object {
                if ($_ -match '\]\s*(\d+)%') {
                    Write-CustomProgress -Activity 'Installing Android NDK' `
                        -Status ('{0}% Complete:' -f $Matches[1]) `
                        -PercentComplete $Matches[1]
                } else {
                    $_
                }
            } -End {
                Write-CustomProgress -Activity 'Installing Android NDK' -Completed
            }
        if (-not $?) { throw 'Error detected' }
        Set-EnvVar ANDROID_NDK_ROOT "$ndk_dir" Machine
        Set-EnvVar ANDROID_NDK_HOST "windows-x86_64" Machine
    } `
    -UninstallCmd {
        Remove-EnvVar ANDROID_NDK_ROOT Machine
        Remove-EnvVar ANDROID_NDK_HOST Machine
        if (Test-Path "$ndk_dir" -Type Container) {
            Remove-Path "$ndk_dir" -Recurse -Force
        }
    }
