Add-PackageInfo `
    -Name "Conan_config_remote" `
    -Description "Conan config: add remote" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Conan") `
    -FindCmd {
        if ((conan remote list | Select-String '^bincrafters:' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
        if (-not $?) { throw 'Error detected' }
    }
