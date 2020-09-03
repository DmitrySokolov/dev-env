<#
.SYNOPSIS
    Manages development environment by installing/uninstalling/updating apps listed in "config.json" file.

.LINK
    Copyright 2019-2020 Dmitry Sokolov <mr.dmitry.sokolov@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


.DESCRIPTION
    Manages development environment. The "config.json" file should contain description
    of apps to install. Supported commands are "install", "uninstall", "update".

.PARAMETER Command
    Supported commands: install, uninstall, update. Default: "install".
.PARAMETER Config
    Optional, config file_name. Default: "$script_dir\config.json".
.PARAMETER Kit
    Optional, kit name(s). Default: "default".
.PARAMETER InstallDir
    Optional, root directory to install apps. Default: "C:\Dev\Tools".
.PARAMETER PackagesDir
    Optional, directory with package info files . Default: "$script_dir\packages".
.PARAMETER CacheDir
    Optional, directory to keep downloaded files. Default: "$script_dir\cache".
.PARAMETER UserName
    Optional, user name ("$user_name" variable for "config.json"). Default: "build.bot".
.PARAMETER UserInfo
    Optional, user info ("$user_info" variable for "config.json"). Default: "Build Bot <build.bot@example.org>".
.PARAMETER Credential
    Optional, credential that will be available in packages. If $null is passed, password will be acquired using Read-Host.
.PARAMETER DryRun
    Optional, flag that controls the actual execution of commands, default: $false.
.PARAMETER Verbosity
    Optional, verbosity level, default: 1, supported: [0=always, 1=normal, 2=detail, 3=trace].
.PARAMETER WorkerMode
    Internal.
#>


# Command-line parameters
[CmdletBinding()] param (
    [ValidateSet('install', 'uninstall', 'update')]
    [string] $Command = 'install',
    [string] $Config = '.\config.json',
    [string[]] $Kit = @('default'),
    [string] $InstallDir = '',
    [string] $PackagesDir = '',
    [string] $CacheDir = '',
    [string] $UserName = '',
    [string] $UserInfo = '',
    [pscredential] $Credential = $null,
    [switch] $DryRun = $false,
    [int]    $Verbosity = 1,
    [switch] $WorkerMode = $false,
    [switch] $DebugMode = $false
)


$ScriptDir = Split-Path $MyInvocation.MyCommand.Source -Parent

$IsElevatedPS = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$V_ALWAYS = 0
$V_NORMAL = 1
$V_DETAIL = 2
$V_TRACE  = 3

$LoggerFn = 'Write-Host'


function Write-Log
{
    [CmdletBinding(PositionalBinding=$false)] param (
        [Parameter(Position=0)][int] $Level,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)] $Params,
        [string] $Color = 'Default'
    )
    if ($Verbosity -ge $Level) {
        $opt = if ($Color -ne 'Default') { @{ForegroundColor=$Color} } else { @{} }
        Write-Output $Params -NoEnumerate | ForEach-Object { & $LoggerFn @_ @opt }
    }
}


function Write-CustomProgress
{
    if (-not $WorkerMode) {
        Write-Progress @args
    } else {
        Write-Output $args -NoEnumerate | ForEach-Object {
            Write-Log $V_ALWAYS 'Write-Progress' @_
        }
    }
}


function Expand-String
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string] $Value
    )
    return "@`"`n$Value`n`"@" | Invoke-Expression
}


function Invoke-Cmd
{
    [CmdletBinding(PositionalBinding=$false)] param (
        [Parameter(Position=0)][scriptblock] $Cmd,
        [scriptblock] $Check = $null,
        [string] $ErrorMsg = "`nFailed!",
        [switch] $ReturnOutput = $false,
        [switch] $NoEcho = $false
    )
    if (-not $NoEcho) {
        $cmd_ = "$Cmd".Trim()
        Write-Log $V_NORMAL "PS >  $cmd_`n"
    }
    if (-not $DryRun) {
        $failed_ = $false
        try {
            $output = & $Cmd 2>&1 | ForEach-Object {
                if (-not $NoEcho) { Write-Log $V_NORMAL $_ }
                Write-Output $_
            } | Out-String
            if ($Check -is [scriptblock]) { $failed_ = -not (& $Check) }
        }
        catch {
            $failed_ = $true
            Write-Log $V_ALWAYS $Error[0].ToString() -Color Red
        }
        if ($failed_) { throw $ErrorMsg }
        if ($ReturnOutput) { return $output }
    }
    if ($ReturnOutput) { return '' }
}


function Select-NonEmpty ($default)
{
    foreach ($a in $args) {
        $s = $a.Trim()
        if ($s.Length -gt 0) { return $s }
    }
    return $default
}


function Select-NonEmptyPath ($default)
{
    return [System.IO.Path]::GetFullPath((Select-NonEmpty @args -default $default))
}


function Set-EnvVar
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $Name,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string] $Value,
        [string] $Target = 'Machine'
    )
    if ($Name -match 'Path$') {
        $Value = ((($env:Path + ";$Value") -replace ';;',';') -split ';' | Select-Object -Unique) -join ';'
    }
    Write-Log $V_NORMAL "PS >  Set-EnvVar '$Name' '$Value' '$Target'"
    if (-not $DryRun) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
    }
}


function Remove-EnvVar
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string]$Name,
        [string] $Value = '',
        [string] $Target = 'Machine'
    )
    if ($Name -match 'Path$') {
        $Value = ((($env:Path -replace [regex]::Escape($Value),'') -replace ';;',';') -split ';' | Select-Object -Unique) -join ';'
    } else {
        $Value = $null
    }
    Write-Log $V_NORMAL "PS >  Remove-EnvVar '$Name'"
    if (-not $DryRun) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
    }
}


function Test-PathExists
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $Path,
        [Microsoft.PowerShell.Commands.TestPathType] $Type = [Microsoft.PowerShell.Commands.TestPathType]::Any,
        [switch] $Throw
    )
    if (Test-Path $Path -Type:$Type) { return $true }
    if ($Throw) { throw 'Not found' }
    return $false
}


function Test-Match
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $Value,
        [Parameter(Mandatory=$true)][string] $Pattern,
        [switch] $Match,
        [switch] $NotMatch,
        [switch] $Throw
    )
    $success = if ($Match) {
        $Value -match $Pattern
    } elseif ($NotMatch) {
        $Value -notMatch $Pattern
    } else {
        throw 'Test-Match error: either -Match, or -NotMatch should be specified'
    }
    if ($Throw -and -not $success) { throw 'Test-Match failed' }
    return $success
}


function Test-EnvVar
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $Name,
        [string] $Kind = '',
        [string] $Value = '',
        [switch] $Throw
    )
    if (Test-Path env:$Name) {
        $v = [Environment]::GetEnvironmentVariable($Name)
        switch ($Kind) {
            'isFile'   { return (Test-PathExists $v -Type:Leaf -Throw:$Throw) }
            'isDir'    { return (Test-PathExists $v -Type:Container -Throw:$Throw) }
            'match'    { return (Test-Match $v -Match $Value -Throw:$Throw) }
            'notMatch' { return (Test-Match $v -NotMatch $Value -Throw:$Throw) }
        }
        throw "Test-EnvVar error: unknown -Kind '$Kind'"
    }
    if ($Throw) { throw 'Not found' }
    return $false
}


function Update-Environment
{
    foreach($level in 'Machine','User') {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            # For Path variables, append the new values, if they're not already in there
            if ($_.Name -match 'Path$') {
                $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select-Object -Unique) -join ';'
            } ; $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
}


function New-FileShortcut
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $ShortcutFile,
        [Parameter(Mandatory=$true)][string] $TargetPath,
        [string] $Arguments = $null,
        [string] $Description = $null,
        [string] $WorkingDir = $null
    )
    New-Item -ItemType Directory -Path (Split-Path $ShortcutFile)
    $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($ShortcutFile)
    $lnk.TargetPath = $TargetPath
    if ($null -ne $Arguments) { $lnk.Arguments = $Arguments }
    if ($null -ne $Description) { $lnk.Description = $Description }
    if ($null -ne $WorkingDir) { $lnk.WorkingDirectory = $WorkingDir }
    $lnk.Save()
}


function Get-WebFile ($url)
{
    $f = Split-Path $url -Leaf
    Invoke-WebRequest $url -OutFile $f
    return $f
}


function Import-Conf
{
    # Get config file
    $conf_file = if ($Config -match '^http') { Get-WebFile $Config } else { $Config }
    $conf_file = (Resolve-Path $conf_file).Path
    if (-not (Test-Path $conf_file)) { $conf_file = Join-Path $ScriptDir $conf_file }
    if (-not (Test-Path $conf_file)) { throw "ERROR: could not find '$Config', nothing to install." }

    # Parse JSON
    return ((Get-Content $conf_file) -join "" | ConvertFrom-Json), $conf_file
}


function Initialize-Vars ($conf, $conf_file)
{
    Set-Variable script_dir $ScriptDir -Scope 1
    Set-Variable config_dir (Split-Path $conf_file -Parent) -Scope 1
    Set-Variable packages_dir (Select-NonEmptyPath $PackagesDir (Expand-String $conf.packages_dir) -default "$ScriptDir\packages") -Scope 1
    Set-Variable cache_dir (Select-NonEmptyPath $CacheDir (Expand-String $conf.cache_dir) -default "$ScriptDir\cache") -Scope 1
    Set-Variable install_dir (Select-NonEmptyPath $InstallDir (Expand-String $conf.install_dir) -default 'C:\Dev\Tools') -Scope 1
    Set-Variable user_name (Select-NonEmpty $UserName (Expand-String $conf.user_name) -default 'build.bot') -Scope 1
    Set-Variable user_info (Select-NonEmpty $UserInfo (Expand-String $conf.user_info) -default 'Build Bot <build.bot@example.org>') -Scope 1
}


function New-PackageId ($name, $version)
{
    if ($version -eq 'none') {
        return $name
    } else {
        return '{0}__{1}' -f $name,$version
    }
}


function Add-PackageInfo
{
    [CmdletBinding()] param (
        [Parameter(Mandatory=$true)][string] $Name,
        [Parameter(Mandatory=$true)][string] $Version,
        [Parameter(Mandatory=$true)][string] $Platform,
        [string] $Description = '',
        [string] $Url = 'none',
        [string] $FileName = 'none',
        [bool] $RequiresElevatedPS = $false,
        [bool] $IsMetaPackage = $false,
        [string[]] $DependsOn = @(),
        [scriptblock] $InitCmd,
        [scriptblock] $FindCmd,
        [scriptblock] $InstallCmd,
        [scriptblock] $UninstallCmd
    )

    $pkg_id = New-PackageId $Name $Version

    Write-Log $V_DETAIL "PS >  Add-PackageInfo '$pkg_id'"

    if ($Script:Packages -isNot [hashtable]) {
        $Script:Packages = @{}
    }
    $Script:Packages[$pkg_id] = @{
        Name = $Name
        Description = $Description
        Version = $Version
        Platform = $Platform
        Url = $Url
        FileName = $FileName
        RequiresElevatedPS = $RequiresElevatedPS
        IsMetaPackage = $IsMetaPackage
        DependsOn = $DependsOn
        InitCmd = $InitCmd
        FindCmd = $FindCmd
        InstallCmd = $InstallCmd
        UninstallCmd = $UninstallCmd
        Installer = "$cache_dir\$(if ($FileName -eq 'from_url') {Split-Path $Url -Leaf} else {$FileName})"
    }
}


function IsRequiredElevatedPS ($pkg_list)
{
    return ($pkg_list.Where({ $Script:Packages.$_.RequiresElevatedPS }, 'SkipUntil', 1)).Count -gt 0
}


function Get-KitPackages ($kits, $kit_name)
{
    foreach ($name in $kits.$kit_name) {
        if ($name -match '^kit:(.+)$') {
            Get-KitPackages $kits $Matches[1] | Write-Output
        } else {
            $name | Write-Output
        }
    }
}


function ListContainsAny ([string[]] $list, [string[]] $names)
{
    foreach ($n in $names) {
        if ($list -contains $n) {return $true}
    }
    return $false
}


function Get-PkgDependenciesImpl ([string] $pkg_name, [ref] $processed_list)
{
    if ($pkg_name -notIn $processed_list.Value) {
        $processed_list.Value += $pkg_name
        foreach ($name in $Script:Packages.$pkg_name.DependsOn) {
            $alt = $name.Split('|')
            if (-not (ListContainsAny $processed_list.Value $alt)) {
                Get-PkgDependenciesImpl $alt[0] $processed_list | Write-Output
            }
        }
        $pkg_name | Write-Output
    }
}


function Get-PkgDependencies ([string[]] $pkg_names)
{
    $result = @()
    $processed_list = @()
    foreach ($name in $pkg_names) {
        Get-PkgDependenciesImpl $name ([ref]$processed_list) | ForEach-Object {
            if ($Script:Packages.Keys -notContains $_) { throw "`nError: unknown package '$_'"}
            $result += $_
            Write-Log $V_NORMAL "-- $($_ -replace '__',' ')"
        }
    }
    return $result
}


function Get-PkgInstaller ($url, $out_file)
{
    if ($url -ne 'none') {
        if (Test-Path $out_file -PathType Leaf) {  # Get package from cache
            Write-Log $V_DETAIL '-- Found' (Split-Path $out_file -Leaf) 'in cache'
        } else {  # Download package
            Write-Log $V_NORMAL '-- Downloading' $url
            Invoke-Cmd { Invoke-WebRequest $url -OutFile $out_file }
        }
    }
}


function Get-PkgDescription ([hashtable] $pkg)
{
    if ($pkg.Version -ne 'none') { return ($pkg.Description -f $pkg.Version) }
    return $pkg.Description
}


function Install-Pkg ([hashtable] $pkg)
{
    $full_descr = Get-PkgDescription $pkg
    # Check if it is meta package
    if ($pkg.IsMetaPackage  -and  $pkg.InstallCmd -isNot [scriptblock]) {
        Write-Log $V_NORMAL "-- Installed $full_descr"
        return
    }
    # Run InitCmd
    if ($pkg.InitCmd -is [scriptblock]) {
        & $pkg.InitCmd
    }
    # Run FindCmd
    if ($pkg.FindCmd -is [scriptblock]) {
        Write-Log $V_NORMAL "-- Searching for installed $full_descr"
        try {
            & $pkg.FindCmd | Out-Null
            Write-Log $V_NORMAL "-- Found $full_descr installed"
            return
        }
        catch {
            $Error.RemoveAt(0)
        }
        Write-Log $V_NORMAL "-- Not installed"
    }
    # Get package installer
    Get-PkgInstaller $pkg.Url $pkg.Installer
    # Run InstallCmd
    Write-Log $V_NORMAL "-- Installing  $full_descr"
    if ($pkg.InstallCmd -is [scriptblock]) {
        Invoke-Cmd $pkg.InstallCmd
        Update-Environment
    } else {
        Write-Log $V_NORMAL '-- No command is defined'
    }
}


function Uninstall-Pkg ([hashtable] $pkg)
{
    $full_descr = Get-PkgDescription $pkg
    # Check if it is meta package
    if ($pkg.IsMetaPackage  -and  $pkg.UninstallCmd -isNot [scriptblock]) {
        Write-Log $V_NORMAL "-- Uninstalled $full_descr"
        return
    }
    # Run InitCmd
    if ($pkg.InitCmd -is [scriptblock]) {
        & $pkg.InitCmd
    }
    # Get package installer
    Get-PkgInstaller $pkg.Url $pkg.Installer
    # Run UninstallCmd
    Write-Log $V_NORMAL "-- Uninstalling  $full_descr"
    if ($pkg.UninstallCmd -is [scriptblock]) {
        Invoke-Cmd $pkg.UninstallCmd
        Update-Environment
    } else {
        Write-Log $V_NORMAL '-- No command is defined'
    }
}


function Start-NPipeServer ($pipe_name = "dev_env_pipe")
{
    $Script:PipeServer = [System.IO.Pipes.NamedPipeServerStream]::new($pipe_name,
        [System.IO.Pipes.PipeDirection]::InOut)
    $Script:PipeServer.WaitForConnection()
    $Script:PipeReader = [System.IO.StreamReader]::new($Script:PipeServer)
    $Script:PipeWriter = [System.IO.StreamWriter]::new($Script:PipeServer)
    $Script:PipeWriter.AutoFlush = $true
}


function Start-NPipeClient ($pipe_name = "dev_env_pipe")
{
    $Script:PipeClient = [System.IO.Pipes.NamedPipeClientStream]::new(".", $pipe_name,
        [System.IO.Pipes.PipeDirection]::InOut,
        [System.IO.Pipes.PipeOptions]::None,
        [System.Security.Principal.TokenImpersonationLevel]::Impersonation)
    $Script:PipeClient.Connect()
    $Script:PipeReader = [System.IO.StreamReader]::new($Script:PipeClient)
    $Script:PipeWriter = [System.IO.StreamWriter]::new($Script:PipeClient)
    $Script:PipeWriter.AutoFlush = $true
}


function worker_debug_output
{
    if ($DebugMode -and $WorkerMode) { Write-Host @args }
}


function Write-Pipe
{
    [CmdletBinding()] param (
        [Parameter(Position=0, ValueFromPipeline=$true)] $var
    )
    $type = $var.GetType().Name
    $Script:PipeWriter.WriteLine($type)
    worker_debug_output "`n`nWrite-Pipe`n  Type: $type"
    switch ($type) {
        'Hashtable' {
            $h = @{}
            foreach ($k in $var.Keys) {
                if ($null -eq $var[$k]) {
                    $h[$k] = 'null;null'
                    continue
                }
                switch ($var[$k].GetType().Name) {
                    'ScriptBlock' { $h[$k] = '{0};{1}' -f $_, $var[$k] }
                    Default       { $h[$k] = '{0};{1}' -f $_, (ConvertTo-Json $var[$k] -C) }
                }
            }
            $s = $h | ConvertTo-Json -Depth 10 -Compress
            $Script:PipeWriter.WriteLine($s)
            worker_debug_output "  Value: $s"
        }
        Default {
            $s = $var | ConvertTo-Json -Depth 10 -Compress
            $Script:PipeWriter.WriteLine($s)
            worker_debug_output "  Value: $s"
        }
    }
}


function Read-Pipe
{
    $type = $Script:PipeReader.ReadLine()
    $var = $Script:PipeReader.ReadLine()
    switch ($type) {
        $null {
            return $null
        }
        'Hashtable' {
            $h = @{}
            (ConvertFrom-Json $var).PSObject.Properties | ForEach-Object {
                $k = $_.Name
                $type, $val = $_.Value -split ';', 2
                switch ($type) {
                    'ScriptBlock' { $h[$k] = [scriptblock]::Create($val) }
                    'null'        { $h[$k] = $null }
                    Default       { $h[$k] = ConvertFrom-Json $val }
                }
            }
            return $h
        }
        Default {
            return ConvertFrom-Json $var
        }
    }
}


function Send-Command ($cmd, $pkg)
{
    Write-Pipe $cmd
    Write-Pipe $pkg
}


function Receive-Command
{
    $cmd = Read-Pipe
    $pkg = Read-Pipe
    return $cmd, $pkg
}


function Send-CommandOutput ($text)
{
    Write-Pipe 'Output:start'
    if ($text -is [scriptblock]) {
        try {
            # Just execute a command, output is already redirected
            & $text
        }
        catch {
            Write-Log $V_ALWAYS $Error[0].ToString() -Color Red
            Write-Pipe 'Output:error'
            return
        }
    } else {
        Write-Pipe $text
    }
    Write-Pipe 'Output:finish'
}


function Receive-CommandOutput
{
    $cmd = Read-Pipe
    if ($cmd -ne 'Output:start') {
        throw "Recieved unexpected output: '$cmd' (expected: 'Output:start')"
    }
    $done = $false
    while (-not $done) {
        $line = Read-Pipe
        if ($null -eq $line) {
            $done = $true
        } elseif ('Output:finish' -eq $line) {
            $done = $true
        } elseif ('Output:error' -eq $line) {
            throw "`nExiting..."
        } else {
            $a = @() ; $o = @{} ; $arr = @($line)
            for ($i=0; $i -lt $arr.Length; $i+=1) {
                if ($arr[$i] -match '^-(NoNewLine|Completed):?') {
                    $o[$Matches[1]] = $true
                } elseif ($arr[$i] -match '^-(Activity|Status|PercentComplete):?' -and ($i+1) -lt $arr.Length) {
                    $o[$Matches[1]] = $arr[$i+1] ; $i+=1
                } elseif ($arr[$i] -match '^-ForegroundColor:?' -and ($i+1) -lt $arr.Length) {
                    $o['Color'] = $arr[$i+1] ; $i+=1
                } else {
                    $a += $arr[$i]
                }
            }
            if ($a[0] -eq 'Write-Progress') {
                $a = $a[1..[Math]::Max(1, $a.Count-1)]
                Write-Progress @a @o
            } else {
                Write-Log $V_NORMAL @a @o
            }
        }
    }
}


function dispatch ($cmd, $pkg)
{
    if (-not $pkg.RequiresElevatedPS  -or  $IsElevatedPS) {
        # Run command
        & $cmd $pkg
    } else {
        # Send command to elevated shell
        Send-Command $cmd $pkg
        Receive-CommandOutput
        Update-Environment
    }
}


function pipe_logger
{
    Write-Pipe $args
}


function start_worker
{
    try {
        # Init variables required for substitution
        $conf, $conf_file = Import-Conf
        Initialize-Vars $conf $conf_file

        Start-NPipeClient

        # Redirect log to pipe
        $Script:LoggerFn = 'pipe_logger'

        $stopped = $false
        while (-not $stopped) {
            $cmd, $pkg = Receive-Command
            switch ($cmd) {
                'Install-Pkg'   { Send-CommandOutput {Install-Pkg $pkg} }
                'Uninstall-Pkg' { Send-CommandOutput {Uninstall-Pkg $pkg} }
                'Stop-Worker'   { $stopped = $true }
                Default         { Send-CommandOutput "Received unknown command: '$cmd'"}
            }
        }
    }
    catch {
        Write-Log $V_ALWAYS $Error[0].ToString() -Color Red
        exit 1
    }
    finally {
        $Script:PipeWriter.Close()
        $Script:PipeReader.Close()
        $Script:PipeClient.Dispose()
        $Script:PipeWriter = $null
        $Script:PipeReader = $null
        $Script:PipeClient = $null
    }
}


function main
{
    try {
        $conf, $conf_file = Import-Conf

        # Init variables required for substitution
        Initialize-Vars $conf $conf_file
        Write-Log $V_DETAIL "Config:"
        Write-Log $V_DETAIL "-- Script dir   : $script_dir"
        Write-Log $V_DETAIL "-- Config dir   : $config_dir"
        Write-Log $V_DETAIL "-- Packages dir : $packages_dir"
        Write-Log $V_DETAIL "-- Cache dir    : $cache_dir"
        Write-Log $V_DETAIL "-- Install dir  : $install_dir"
        Write-Log $V_DETAIL "-- User name    : $user_name"
        Write-Log $V_DETAIL "-- User info    : $user_info"
        Write-Log $V_DETAIL ""

        if ($Script:PSBoundParameters.ContainsKey('Credential') `
                -and $null -eq $Script:PSBoundParameters.Credential) {
            $passw = Read-Host "Enter password" -AsSecureString
            $Script:PSBoundParameters.Credential = [pscredential]::new($user_name, $passw)
            $passw = $null
            Write-Log $V_DETAIL ""
        }

        # Read packages info
        Get-ChildItem "$packages_dir\*.ps1" -Recurse -Force `
            | ForEach-Object { . $_.FullName }

        Write-Log $V_NORMAL "`nPackages to process:"

        # Collect all package names from all selected kits
        $package_list = $Kit | ForEach-Object { Get-KitPackages $conf.kits $_ }

        # Get ordered package list
        $ordered_list = Get-PkgDependencies $package_list

        # If there are packages that require elevation run elevated PS and setup client-server mode
        if ((IsRequiredElevatedPS $ordered_list)  -and  -not $IsElevatedPS) {
            Write-Log $V_ALWAYS "`nSome packages require Admin privileges to install, trying to elevate privileges..."
            $opt = if ($DebugMode) { "-NoExit" } else { "-NonInteractive" }
            $ps_args = @(
                $opt,
                "-File", $PSCommandPath,
                $Command,
                "-Config", ('"{0}"' -f $conf_file),
                "-Kit", ('"{0}"' -f ($Kit -join '","')),
                "-InstallDir", ('"{0}"' -f $install_dir),
                "-PackagesDir", ('"{0}"' -f $packages_dir),
                "-CacheDir", ('"{0}"' -f $cache_dir),
                "-UserName", ('"{0}"' -f $user_name),
                "-UserInfo", ('"{0}"' -f $user_info),
                "-Verbosity", ('"{0}"' -f $Verbosity),
                "-WorkerMode")
            if ($DryRun) { $ps_args += "-DryRun" }
            if ($DebugMode) { $ps_args += "-DebugMode" }
            $arg = if ($DebugMode) { @{} } else { @{WindowStyle='Hidden'} }
            $ps_obj = Start-Process powershell.exe $ps_args -WorkingDirectory $PWD -Verb RunAs -PassThru @arg
            Start-Sleep -Milliseconds 500
            if (-not $ps_obj  -or  $ps_obj.HasExited) { throw "`nError: could not run this script with elevated privileges`n" }
            Start-NPipeServer
        }

        if ($Command -eq 'install') {
            foreach ($name in $ordered_list) {
                Write-Log $V_NORMAL "`n$($name -replace '__',' '):"
                dispatch 'Install-Pkg' $Script:Packages.$name
            }
        }
        elseif ($Command -eq 'uninstall') {
            [array]::Reverse($ordered_list)
            foreach ($name in $ordered_list) {
                Write-Log $V_NORMAL "`n$($name -replace '__',' '):"
                dispatch 'Uninstall-Pkg' $Script:Packages.$name
            }
        }
        elseif ($Command -eq 'update') {
            throw "`nNot implemented."
        }
        else {
            throw "`nError: unsupported command."
        }
    }
    catch {
        Write-Log $V_ALWAYS $Error[0].ToString() -Color Red
        exit 1
    }
    finally {
        if ($null -ne $Script:PipeServer) {
            if ($Script:PipeServer.IsConnected) {
                Send-Command 'Stop-Worker' 'now'
                Start-Sleep -Milliseconds 100
            }
            $Script:PipeWriter.Close()
            $Script:PipeReader.Close()
            $Script:PipeServer.Dispose()
            $Script:PipeWriter = $null
            $Script:PipeReader = $null
            $Script:PipeServer = $null
        }
    }
}


if ($WorkerMode) {
    start_worker
} else {
    main
}
