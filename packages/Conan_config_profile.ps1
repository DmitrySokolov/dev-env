Add-PackageInfo `
    -Name "Conan_config_profile" `
    -Description "Conan config: add default profile" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Conan") `
    -FindCmd {
        conan profile get settings.os default 2>&1 | Out-Null ; $?
    } `
    -InstallCmd {
        conan profile new default --detect
    }
