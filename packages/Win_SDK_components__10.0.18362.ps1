Add-PackageInfo `
    -Name "Win_SDK_components" `
    -Description "Components of Windows SDK v{0}" `
    -Version "10.0.18362" `
    -Platform "x86_64" `
    -DependsOn @("VS_2019|VS_build_tools_2019") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable reg_key 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots' -Scope 1
        Set-Variable reg_prop 'WindowsDebuggersRoot10' -Scope 1
    } `
    -FindCmd {
        $obj = Get-Item $reg_key
        $null -ne $obj  -and  $obj.Property -contains $reg_prop
    } `
    -InstallCmd {
        $win_sdk_installer = (Get-Package `
            | Where-Object Name -match 'Windows Software Development Kit' `
            | Where-Object Version -match ('\b'+ $Pkg.Version +'\b')
            ).Metadata.BundleCachePath
        & $win_sdk_installer /features OptionId.WindowsDesktopDebuggers /quiet /norestart /ceip off | Out-Default
        Set-EnvVar Path (Join-Path (Get-ItemPropertyValue $reg_key -Name $reg_prop) x64) Machine
    } `
    -UninstallCmd {
        $win_sdk_installer = (Get-Package `
            | Where-Object Name -match 'Windows Software Development Kit' `
            | Where-Object Version -match ('\b'+ $Pkg.Version +'\b') `
            ).Metadata.BundleCachePath
        & $win_sdk_installer /uninstall /quiet /norestart | Out-Default
        Remove-EnvVar Path (Join-Path (Get-ItemPropertyValue $reg_key -Name $reg_prop) x64) Machine
    }
