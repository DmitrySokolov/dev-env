Add-PackageInfo `
    -Name "Win_SDK_components" `
    -Description "Components of Windows SDK v{0}" `
    -Version "10.0.19041" `
    -Platform "x86_64" `
    -DependsOn @("VS_2019|VS_build_tools_2019") `
    -RequiresElevatedPS $true `
    -InitCmd {
        Set-Variable reg_key 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots' -Scope 1
        Set-Variable reg_prop 'WindowsDebuggersRoot10' -Scope 1
    } `
    -FindCmd {
        Test-PathExists $reg_key -Throw
        if ((Get-Item $reg_key).Property -notContains $reg_prop) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        $pkg = Get-Package `
            | Where-Object Name -match 'Windows Software Development Kit' `
            | Where-Object Version -match '\.19041\.'
        if ($null -eq $pkg) { throw 'Error: could not find WinSDK installed' }
        $win_sdk_installer = $pkg.Metadata['BundleCachePath']
        & $win_sdk_installer /features OptionId.WindowsDesktopDebuggers /quiet /norestart /ceip off | Out-Default
        if (-not $?) { throw 'Error detected' }
        Set-EnvVar Path (Join-Path (Get-ItemPropertyValue $reg_key -Name $reg_prop) x64) Machine
    } `
    -UninstallCmd {
        Remove-EnvVar Path (Join-Path (Get-ItemPropertyValue $reg_key -Name $reg_prop) x64) Machine
        $pkg = Get-Package `
            | Where-Object Name -match 'Windows Software Development Kit' `
            | Where-Object Version -match '\.19041\.'
        if ($null -eq $pkg) { throw 'Error: could not find WinSDK installed' }
        $win_sdk_installer = $pkg.Metadata['BundleCachePath']
        & $win_sdk_installer /uninstall /quiet /norestart | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
