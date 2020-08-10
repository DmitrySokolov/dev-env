Add-PackageInfo `
    -Name "Python_module_pip_autoremove" `
    -Description "Python module: pip-autoremove" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python__3") `
    -FindCmd {
        if ((py -3 -m pip list | Select-String '^pip-autoremove' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        py -3 -m pip install pip-autoremove | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        py -3 -m pip uninstall pip-autoremove | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
