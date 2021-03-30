Add-PackageInfo `
    -Name "JDK" `
    -Description "Java Development Kit v8 [LTS]" `
    -Version "8" `
    -Platform "x86_64" `
    -DependsOn @("JDK__8.0.282.08") `
    -IsMetaPackage $true
