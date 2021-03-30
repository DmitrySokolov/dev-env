Add-PackageInfo `
    -Name "Git" `
    -Description "Git VCS v{0}" `
    -Version "2.31.1" `
    -Platform "x86_64" `
    -Url "https://github.com/git-for-windows/git/releases/download/v2.31.1.windows.1/Git-2.31.1-64-bit.exe" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe git 2>&1 | Out-Null
        if (-not $? -or (git --version | Select-String '\b2\.31\b' -Quiet) -ne $true) {
            throw 'Not found'
        }
    } `
    -InstallCmd {
        Set-Content -Path "$env:Temp\git.ini" -Value @"
[Setup]
Lang=default
Dir="$install_dir\Git"
Group=Git
NoIcons=0
SetupType=default
Components=gitlfs,consolefont,autoupdate
Tasks=
EditorOption=Nano
CustomEditorPath=
DefaultBranchOption= 
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFCommitAsIs
BashTerminalOption=MinTTY
GitPullBehaviorOption=Rebase
UseCredentialManager=Core
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Enabled
EnablePseudoConsoleSupport=Disabled
"@
        & $Pkg.Installer /LOADINF="$env:Temp\git.ini" /SILENT | Out-Default
        $success = $?
        Remove-Item -Path "$env:Temp\git.ini" -Force 2>&1 | Out-Null
        if (-not $success) { throw 'Error detected' }
    } `
    -UninstallCmd {
        if (Test-Path "$env:Temp\git.ini") {
            Remove-Item -Path "$env:Temp\git.ini" -Force 2>&1 | Out-Null
        }
        & "$install_dir\Git\unins000.exe" /SILENT | Out-Default
        if (-not $?) { throw 'Error detected' }
    }
