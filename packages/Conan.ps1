Add-PackageInfo `
    -Name "Conan" `
    -Description "Conan package manager for C++" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python__3", "Python_module_pip", "Python_module_pip_autoremove") `
    -FindCmd {
        where.exe conan 2>&1 | Out-Null
        if (-not $?) { throw 'Not found' }
    } `
    -InstallCmd {
        py -3 -m pip install conan` | Out-Default
        if (-not $?) { throw 'Error detected' }
    } `
    -UninstallCmd {
        pip-autoremove conan -y | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
