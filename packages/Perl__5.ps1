Add-PackageInfo `
    -Name "Perl" `
    -Description "Perl 5 [latest]" `
    -Version "5" `
    -Platform "x86_64" `
    -DependsOn @("Perl__5.32.1.1") `
    -IsMetaPackage $true
