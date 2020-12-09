Add-PackageInfo `
    -Name "Android_SDK_Manager" `
    -Description "Android SDK Manager ({0})" `
    -Version "6858069" `
    -Platform "x86_64" `
    -Url "https://dl.google.com/android/repository/commandlinetools-win-6858069_latest.zip" `
    -FileName "from_url" `
    -DependsOn @("Env_config", "JDK__8") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
        Set-Variable sdk_cmdlinetools_dir "$sdk_dir\cmdline-tools" -Scope 1
        Set-Variable sdk_standalone_manager_dir "$sdk_cmdlinetools_dir\tools" -Scope 1
        Set-Variable sdk_manager "$sdk_standalone_manager_dir\bin\sdkmanager.bat" -Scope 1
    } `
    -FindCmd {
        Test-PathExists $sdk_manager -Throw
    } `
    -InstallCmd {
        Set-EnvVar ANDROID_SDK_ROOT $sdk_dir Machine
        if (-not (Test-Path $sdk_standalone_manager_dir -Type Container)) {
            Expand-Archive -Path $Pkg.Installer -DestinationPath $sdk_cmdlinetools_dir
        }
        Write-Output y `
            | & $sdk_manager `
                "cmdline-tools;latest" `
            | ForEach-Object {
                if ($_ -match '\]\s*(\d+)%') {
                    Write-CustomProgress -Activity 'Installing Android SDK Manager' `
                        -Status ('{0}% Complete:' -f $Matches[1]) `
                        -PercentComplete $Matches[1]
                } else {
                    $_
                }
            } -End {
                Write-CustomProgress -Activity 'Installing Android SDK Manager' -Completed
            }
        Remove-Item "$sdk_standalone_manager_dir" -Recurse -Force
    } `
    -UninstallCmd {
        Remove-Item $sdk_cmdlinetools_dir -Recurse -Force
    }
