Add-PackageInfo `
    -Name "DirectX_SDK" `
    -Description "DirectX SDK 9 [latest]" `
    -Version "9" `
    -Platform "x86_64" `
    -DependsOn @("DirectX_SDK__9.29.1962") `
    -IsMetaPackage $true
