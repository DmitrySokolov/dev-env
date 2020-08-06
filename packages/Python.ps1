Add-PackageInfo `
    -Name "Python" `
    -Description "Python [latest]" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Python__3") `
    -IsMetaPackage $true
