Add-PackageInfo `
    -Name "Android_dev" `
    -Description "Android dev tools, SDK, NDK" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Android_SDK_Manager", "Android_SDK__30", "Android_NDK__21.3.6528147") `
    -IsMetaPackage $true `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable root_dir "$install_dir\Android" -Scope 1
        Set-Variable sdk_dir "$root_dir\Sdk" -Scope 1
    } `
    -UninstallCmd {
        Remove-Item $sdk_dir -Recurse -Force
        if ($null -eq (Get-ChildItem $root_dir)) { Remove-Item $root_dir }
        Remove-EnvVar ANDROID_SDK_ROOT Machine
    }
