Add-PackageInfo `
    -Name "Env_config" `
    -Description "Environment variables" `
    -Version "none" `
    -Platform "x86_64" `
    -FindCmd {
        Test-EnvVar HOME isDir
    } `
    -InstallCmd {
        Set-EnvVar HOME $Env:UserProfile User
        Set-EnvVar MSYS2_PATH_TYPE inherit User
    }
