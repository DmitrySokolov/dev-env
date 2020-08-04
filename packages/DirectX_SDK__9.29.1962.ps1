Add-PackageInfo `
    -Name "DirectX_SDK" `
    -Description "DirectX SDK v{0}" `
    -Version "9.29.1962" `
    -Platform "x86_64" `
    -DependsOn @("Env_config__1.0") `
    -RequiresElevatedPS $true `
    -FindCmd {
        Test-EnvVar DXSDK_DIR isDir
    } `
    -InstallCmd {
        $dx_dir = "${env:ProgramFiles(x86)}\Microsoft SDKs\DirectX SDK (June 2010)"
        & $Pkg.Installer /P $dx_dir /U | Out-Default
        Set-EnvVar DXSDK_DIR $dx_dir
    } `
    -UninstallCmd {
        $reg_key = 'HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft DirectX SDK (June 2010)'
        $reg_prop = 'UninstallString'
        & (Get-ItemPropertyValue $reg_key -Name $reg_prop) /U | Out-Default
        Remove-EnvVar DXSDK_DIR
    }
