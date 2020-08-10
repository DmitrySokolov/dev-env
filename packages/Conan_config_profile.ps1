Add-PackageInfo `
    -Name "Conan_config_profile" `
    -Description "Conan config: add default profile" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Conan", "VS_2019|VS_build_tools_2019|Android_NDK__21.0.6113669") `
    -FindCmd {
        conan profile get settings.os default 2>&1 | Out-Null
        if (-not $?) { throw 'Error detected' }
    } `
    -InstallCmd {
        conan profile new default --detect
        if (-not $?) { throw 'Error detected' }
    }
