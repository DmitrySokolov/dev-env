Add-PackageInfo `
    -Name "Perl_module_XML_DOM" `
    -Description "Perl module: XML::DOM" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("Perl") `
    -FindCmd {
        if ($null -eq (perldoc -l XML::DOM 2>$null)) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        cpan XML::DOM | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
