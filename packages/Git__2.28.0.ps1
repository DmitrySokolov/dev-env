Add-PackageInfo `
    -Name "Git" `
    -Description "Git VCS v{0}" `
    -Version "2.28.0" `
    -Platform "x86_64" `
    -Url "https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/Git-2.28.0-64-bit.exe" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        where.exe git 2>&1 | Out-Null
        if ($?) { (git --version | Select-String '\b2\.28\b' -Quiet) -eq $true } else { $? }
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
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFCommitAsIs
BashTerminalOption=MinTTY
GitPullBehaviorOption=Merge
UseCredentialManager=Enabled
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Enabled
EnablePseudoConsoleSupport=Disabled
"@
        & $Pkg.Installer /LOADINF="$env:Temp\git.ini" /SILENT
        $status = $LASTEXITCODE -eq 0
        Remove-Item -Path ("$env:Temp\git.ini") -Force 2>&1 | Out-Null
        $status
    } `
    -UninstallCmd {
        Remove-Item -Path ("$env:Temp\git.ini") -Force 2>&1 | Out-Null
        & "$install_dir\Git\unins000.exe" /SILENT
    }
