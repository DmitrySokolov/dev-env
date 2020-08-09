Add-PackageInfo `
    -Name "Perl_module_XML_DOM" `
    -Description "Perl module: XML::DOM" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Perl") `
    -FindCmd {
        $null -ne (perldoc -l XML::DOM 2>$null)
    } `
    -InstallCmd {
        cpan XML::DOM | Out-Default
    } `
