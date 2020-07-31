Add-PackageInfo `
    -Name "Conan_config" `
    -Description "Conan config [meta package]" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Conan_config_profile", "Conan_config_remote") `
    -IsMetaPackage $true
