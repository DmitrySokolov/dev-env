Add-PackageInfo `
    -Name "Python" `
    -Description "Python 3 [latest]" `
    -Version "3" `
    -Platform "x86_64" `
    -DependsOn @("Python__3.9.2") `
    -IsMetaPackage $true
