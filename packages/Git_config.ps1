Add-PackageInfo `
    -Name "Git_config" `
    -Description "Git VCS config" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Git") `
    -FindCmd {
        Test-PathExists "$env:USERPROFILE\.gitconfig" -Type Leaf -Throw
    } `
    -InstallCmd {
        git config --global user.name  "$user_name"
        if (-not $?) { throw 'Error detected' }
        git config --global user.email "$user_info"
        if (-not $?) { throw 'Error detected' }
    }
