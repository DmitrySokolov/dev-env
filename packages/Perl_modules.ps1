Add-PackageInfo `
    -Name "Perl_modules" `
    -Description "Perl modules [meta package]" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Perl_module_XML_DOM") `
    -IsMetaPackage $true
