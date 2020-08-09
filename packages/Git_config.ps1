Add-PackageInfo `
    -Name "Git_config" `
    -Description "Git VCS config" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Git") `
    -FindCmd {
        Test-Path "$env:USERPROFILE\.gitconfig" -Type Leaf
    } `
    -InstallCmd {
        git config --global user.name  "$user_name"
        git config --global user.email "$user_info"
    }
