# dev-env

Scripts for managing the development environment.


## Prerequisites

Make sure that you have already allowed the execution of PowerShell scripts, see [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1).


## Usage

Launch the following command to install, for example, the kit `common` (Python 3, Conan, TortoiseHg, Git):

```powershell
& {param($InstallDir, $CacheDir, $Kit, $User, $Info, [switch]$RequirePassw) ; $dst_dir="$InstallDir\dev-env" ; if (-not (Test-Path $dst_dir)) {$url='https://github.com/DmitrySokolov/dev-env/releases/download/v1.0.1/dev-env.zip' ; $tmp="$env:Temp\dev-env.zip" ; $cred=$null ; if ($RequirePassw) {Write-Host "`nEnter password: " -NoNewl ; $passw=Read-Host -AsSecur ; $cred=[pscredential]::new($User,$passw)} ; Invoke-WebRequest $url -Out $tmp -Cred $cred ; Expand-Archive $tmp $dst_dir} ; if ($PWD -ne $dst_dir) {Push-Location $dst_dir} ; .\dev_env.ps1 install -Config .\config.json -Kit $Kit -CacheDir $CacheDir -UserName $User -UserInfo $Info} -InstallDir 'C:\Dev\Tools' -CacheDir "$env:USERPROFILE\Downloads" -Kit 'common' -User 'Your.Name' -Info 'Your Name <your.name@example.org>'
```


It will download and install `dev-env` scripts into the directory `C:\Dev\Tools\dev-env`, after that it will download and install (unattended) apps from the kit `common`. Further you can just launch the script `dev-env.ps1`.

For example, to install the kit `qt` (Qt Creator + CDB plugin):

```powershell
.\dev_env.ps1 install -Config .\config.json -Kit 'qt' -CacheDir "$env:USERPROFILE\Downloads" -User 'Your.Name' -Info 'Your Name <your.name@example.org>'
```
