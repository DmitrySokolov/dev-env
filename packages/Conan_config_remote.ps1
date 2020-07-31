Add-PackageInfo `
    -Name "Conan_config_remote" `
    -Description "Conan config: add remote" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Conan") `
    -FindCmd {
        (conan remote list | Select-String '^bincrafters:' -Quiet) -eq $true
    } `
    -InstallCmd {
        conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
    }
