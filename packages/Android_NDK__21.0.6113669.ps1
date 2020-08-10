Add-PackageInfo `
    -Name "Android_NDK" `
    -Description "Android NDK {0}" `
    -Version "21.0.6113669" `
    -Platform "x86_64" `
    -DependsOn @("Env_config", "Android_SDK_Manager") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable sdk_manager "$sdk_dir\cmdline-tools\latest\bin\sdkmanager" -Scope 1
        Set-Variable ndk_ver "21.0.6113669" -Scope 1
    } `
    -FindCmd {
        Test-PathExists "$sdk_dir\ndk\$ndk_ver" -Type Container -Throw
    } `
    -InstallCmd {
        Write-Output yes `
            | & $sdk_manager `
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
        Set-EnvVar ANDROID_NDK_ROOT "$sdk_dir\ndk\$ndk_ver" Machine
        Set-EnvVar ANDROID_NDK_HOST "windows-x86_64" Machine
    } `
    -UninstallCmd {
        Remove-EnvVar ANDROID_NDK_ROOT Machine
        Remove-EnvVar ANDROID_NDK_HOST Machine
        if (Test-Path "$sdk_dir\ndk\$ndk_ver" -Type Container) {
            Remove-Path "$sdk_dir\ndk\$ndk_ver" -Recurse -Force
        }
    }
