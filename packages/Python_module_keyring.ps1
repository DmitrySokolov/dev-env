Add-PackageInfo `
    -Name "Python_module_keyring" `
    -Description "Python module: keyring" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python__3") `
    -FindCmd {
        if ((py -3 -m pip list | Select-String '^keyring' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        py -3 -m pip install keyring | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        pip-autoremove keyring --yes | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
