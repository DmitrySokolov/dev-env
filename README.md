# dev-env

Scripts for managing the development environment.


## Prerequisites

Make sure that you have already allowed the execution of PowerShell scripts, see [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1).


## Usage

Launch the following command to install, for example, the kit `common` (Python 3, Conan, TortoiseHg, Git):

```powershell
& { param($InstallDir,$CacheDir,$Kit,$UserName,$UserInfo,$Url,[switch]$EnterPassword) ; `
    $dst="$InstallDir\dev-env" ; $opt=@{} ; `
    if ($EnterPassword) { Write-Host "`nUser name: $UserName" ; `
        $psw=Read-Host "Enter password" -AsSec ; `
        $opt.Credential=[pscredential]::new($UserName,$psw) } ; `
    if (-not (Test-Path $dst)) { $t="$env:Temp\dev-env.zip" ; `
        Invoke-WebRequest $Url -Out:$t @opt ; Expand-Archive $t $dst ; Remove-Item $t } ; `
    if ($PWD -ne $dst) { Push-Location $dst } ; `
    .\dev_env.ps1 install -Config:.\config.json -Kit:$Kit -CacheDir:$CacheDir `
        -UserName:$UserName -UserInfo:$UserInfo @opt `
}   -InstallDir 'C:\Dev\Tools' `
    -CacheDir "$env:USERPROFILE\Downloads" `
    -Kit 'common' `
    -UserName 'Your.Name' -UserInfo 'Your Name <your.name@example.org>' `
    -Url 'https://github.com/DmitrySokolov/dev-env/releases/download/v1.1.0/dev_env.zip'
```


It will download and install `dev-env` scripts into the directory `C:\Dev\Tools\dev-env`, after that it will download and install (unattended) apps from the kit `common`. Further you can just launch the script `dev-env.ps1`.

For example, to install the kit `qt` (Qt Creator):

```powershell
.\dev_env.ps1 install -Config .\config.json -Kit 'qt' `
    -CacheDir "$env:USERPROFILE\Downloads" `
    -UserName 'Your.Name' -UserInfo 'Your Name <your.name@example.org>'
```
