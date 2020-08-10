Add-PackageInfo `
    -Name "Python_module_pip" `
    -Description "Python module: pip" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python__3") `
    -FindCmd {
        if ((py -3 -m pip list --outdated | Select-String '^pip' -Quiet) -eq $true) {
            throw 'Outdated'
        }
    } `
    -InstallCmd {
        py -3 -m pip install --upgrade pip | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
