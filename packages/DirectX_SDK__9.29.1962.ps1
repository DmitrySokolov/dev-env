Add-PackageInfo `
    -Name "DirectX_SDK" `
    -Description "DirectX SDK v{0}" `
    -Version "9.29.1962" `
    -Platform "x86_64" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        Test-EnvVar DXSDK_DIR isDir -Throw
    } `
    -InstallCmd {
        $dx_dir = "${env:ProgramFiles(x86)}\Microsoft SDKs\DirectX SDK (June 2010)"
        & $Pkg.Installer /P $dx_dir /U | Out-Default
        if (-not $?) { throw 'Error detected' }
        Set-EnvVar DXSDK_DIR $dx_dir Machine
    } `
    -UninstallCmd {
        Remove-EnvVar DXSDK_DIR Machine
        $reg_key = 'HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft DirectX SDK (June 2010)'
        $reg_prop = 'UninstallString'
        & (Get-ItemPropertyValue $reg_key -Name $reg_prop) /U | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
