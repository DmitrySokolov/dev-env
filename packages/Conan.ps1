Add-PackageInfo `
    -Name "Conan" `
    -Description "Conan package manager for C++" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python3") `
    -FindCmd {
        where.exe conan 2>&1 | Out-Null ; $?
    } `
    -InstallCmd {
        py -3 -m pip install conan pip-autoremove`
    } `
    -UninstallCmd {
        pip-autoremove conan -y
    }
