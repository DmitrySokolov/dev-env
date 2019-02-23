<#
    Copyright 2019 Dmitry Sokolov <mr.dmitry.sokolov@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


.SYNOPSIS
    Manages development environment by installing/uninstalling/updating apps listed in config.json file.

.PARAMETER Command
    Supported commands: install, uninstall, update
.PARAMETER Config
    Optional, config file_name. Default: ".\config.json".
.PARAMETER Kit
    Optional, kit name. Default: "default".
.PARAMETER InstallDir
    Optional, root directory to install apps. Default: "C:\Dev\Tools".
.PARAMETER CacheDir
    Optional, directory to keep downloaded files. Default: ".cache".
.PARAMETER DryRun
    Optional, show only expected commands, do not perform them. Default: "$false".
.PARAMETER V
    Optional, verbosity level. Default: "1".

.DESCRIPTION
    The format of the config.json file:
    {
        "main": {
            "kits": {
                "default": [list of package IDs],
                "another_kit_name": [list of package IDs],
                ...
            },
            "cache_dir": "dir name"                                         // supports vars substitution
            "install_dir": "dir name"                                       // supports vars substitution
        },
        "packages": {
            "pkg_ID": {
                "elevated": "true|false",                                   // requires admin account to install
                "depends_on": ["pkg_ID1", "pkg_ID2", ...],
                "description": "description of a package (or just name)",
                "version": "1.2.3 | none",
                "platform": "x86 | x86_64 | arm | arm64 | mips | mips64",
                "url": "URL | none",
                "file_name": "from_url | custom file name",
                "install_cmd": "command | meta_pkg | none",                 // supports vars substitution
                "uninstall_cmd": "command | meta_pkg | none",               // supports vars substitution
                "test_cmd": "command | none"                                // supports vars substitution
                "vars": {}                                                  // custom variables for xxx_cmd
            },
            ...
        }
    }

    References in Kits: it possible to include the whole Kit in another Kit by enter a reference:
        * "default": ["kit:another_kit_name", "pkg_ID1", ...]

    "cache_dir", "install_dir" support:
        * environment variables in format $env:VAR_NAME

    "install_cmd", "uninstall_cmd", "test_cmd" support:
        * environment variables in format $env:VAR_NAME
        * $install_dir - the directory name specified in -InstallDir param
        * $file_path - the full path of the package installer
        * $version - the value of the property Version of the current package
        * $platform - the value of the property Platform of the current package
        * $($pkg.vars.xxx)
#>

# Command-line parameters
param (
    [string] $Command = '',
    [string] $Config = '.\config.json',
    [string] $Kit = 'default',
    [string] $InstallDir = '',
    [string] $CacheDir = '',
    [switch] $DryRun = $false,
    [int]    $V = 1,
    [switch] $WorkerMode = $false
)

$V_QUIET = 0
$V_NORMAL = 1
$V_HIGH = 2

function Expand-String ( [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string] $value ) {
    "@`"`n$value`n`"@" | Invoke-Expression
}

function Select-NonEmpty ($default) {
    foreach ($a in $args) {
        $s = $a.Trim()
        if ($s.Length -gt 0) { return $s }
    }
    return $default
}

function IIf($condition, $if_true, $if_false) {
    if ($condition -isNot "Boolean") {
        $_ = $condition
    }
    if ($condition) {
        if ($if_true -is "ScriptBlock") { & $if_true } else { $if_true }
    }
    else {
        if ($if_false -is "ScriptBlock") { & $if_false } else { $if_false }
    }
}

$log_output = { Write-Host @_ }
function Write-Log ($level) {
    if ($V -ge $level) {
        Write-Output $args -NoEnumerate | ForEach-Object $log_output
    }
}

function Invoke-Cmd {
    $cmd = $args -join ' '
    Write-Log $V_NORMAL $cmd
    if (!$DryRun) {
        $r = Invoke-Expression ($cmd + ' | Out-Default ; $?')
        if ($r -ne $true) { throw "`nError: command failed`n" }
    }
}

function Invoke-Test {
    $res = 'FAILED', 'OK'
    $clr = 'Yellow', 'Green'
    $cmd = $args -join ' '
    Write-Log $V_HIGH '-- Test : ' $cmd -NoNewLine
    $r = Invoke-Expression ($cmd + ' 2>&1 | Out-Null ; $?')
    Write-Log $V_HIGH ('  [{0}]' -f $res[[int]$r]) -ForegroundColor $clr[[int]$r]
    return $r
}

function Update-Env {
    foreach($level in "Machine","User") {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            # For Path variables, append the new values, if they're not already in there
            if ($_.Name -match 'Path$') {
                $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select-Object -Unique) -join ';'
            } ; $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
}

function Set-EnvVar {
    param ( [Parameter(Mandatory=$true)][string] $name,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string] $value,
            [string] $target = 'Machine' )
    if ($name -match 'Path$') {
        $value = ((($env:Path + ";$value") -replace ';;',';') -split ';' | Select-Object -Unique) -join ';'
    }
    [Environment]::SetEnvironmentVariable($name, $value, $target)
}

function Remove-EnvVar {
    param ( [Parameter(Mandatory=$true)][string] $name,
            [string] $value = '',
            [string] $target = 'Machine' )
    if ($name -match 'Path$') {
        $value = ((($env:Path -replace [regex]::Escape($value),'') -replace ';;',';') -split ';' | Select-Object -Unique) -join ';'
    } else {
        $value = $null
    }
    [Environment]::SetEnvironmentVariable($name, $value, $target)
}

function Test-EnvVar {
    param ( [Parameter(Mandatory=$true)][string] $name,
            [string] $kind = '',
            [string] $value = '' )
    if (-not (Test-Path env:$name)) { return $false }
    $v = [Environment]::GetEnvironmentVariable($name)
    switch ($kind) {
        'isFile'   { return (Test-Path $v -Type Leaf) }
        'isDir'    { return (Test-Path $v -Type Container) }
        'match'    { return ($v -match $value) }
        'notMatch' { return ($v -notMatch $value) }
    }
    return $true
}

function Get-PkgName ($kits, $kit_name) {
    foreach ($name in $kits.$kit_name) {
        if ($name -match '^kit:(.+)$') {
            Get-PkgName $kits $Matches[1] | Write-Output
        } else {
            $name | Write-Output
        }
    }
}

function Get-PkgDependencies ($pkg, $pkg_name, [ref]$processed_list, [ref]$result) {
    if ($pkg_name -notIn $processed_list.Value) {
        $processed_list.Value += $pkg_name
        foreach ($name in $pkg.depends_on) { Get-PkgDependencies $conf.packages.$name $name $processed_list $result }
        $result.Value += $pkg_name
    }
}

function Get-PkgInstaller ($url, $out_file) {
    if ($url -ne "none") {
        if (Test-Path $out_file -PathType Leaf) {
            # Get package from cache
            Write-Log $V_HIGH "-- Found" (Split-Path $out_file -Leaf) "in cache"
        } else {
            # Download package
            Write-Log $V_NORMAL "-- Downloading" $url
            Invoke-Cmd Invoke-WebRequest $url -OutFile $out_file
        }
    }
}

function Get-PkgDescription ($pkg) {
    if ($pkg.version -ne "none") { return ("{0} v{1}" -f $pkg.description, $pkg.version) }
    return $pkg.description
}

function Invoke-PkgCmd ($pkg, $pkg_cmd, $msg, $test=$null) {
    if ($pkg_cmd -eq "none") { return }
    # Init vars
    $version = $pkg.version
    $platform = $pkg.platform
    $file_name = IIf ($pkg.file_name -eq "from_url") {Split-Path $pkg.url -Leaf} $pkg.file_name
    $file_path = Join-Path $cache_dir $file_name
    # Run test
    if ($test -is "ScriptBlock") { if (!(& $test)) {return} }
    # Get package
    Get-PkgInstaller $pkg.url $file_path
    # Invoke command
    Write-Log $V_NORMAL ($msg -f (Get-PkgDescription $pkg))
    Invoke-Cmd (Expand-String $pkg_cmd)
    Update-Env
}

function Install-Pkg ($pkg) {
    if ($pkg.install_cmd -eq "meta_pkg") {
        Write-Log $V_NORMAL ("-- Installed {0}" -f (Get-PkgDescription $pkg))
    } else {
        Invoke-PkgCmd $pkg $pkg.install_cmd "-- Installing {0}" -test {
            # Check if package already installed in OS
            if ($pkg.test_cmd -ne "none" -and (Invoke-Test (Expand-String $pkg.test_cmd))) {
                Write-Log $V_NORMAL ("-- Found {0} installed" -f $pkg.description)
                return $false
            }
            return $true
        }
    }
}

function Uninstall-Pkg ($pkg) {
    if ($pkg.uninstall_cmd -eq "meta_pkg") {
        Write-Log $V_NORMAL ("-- Uninstalled {0}" -f (Get-PkgDescription $pkg))
    } else {
        Invoke-PkgCmd $pkg $pkg.uninstall_cmd "-- Uninstalling {0}"
    }
}

function Start-NPipeServer ($pipe_name = "dev_env_pipe") {
    $pipe_server = New-Object IO.Pipes.NamedPipeServerStream($pipe_name, [IO.Pipes.PipeDirection]::InOut)
    $pipe_server.WaitForConnection()
    $pipe_reader = New-Object IO.StreamReader($pipe_server)
    $pipe_writer = New-Object IO.StreamWriter($pipe_server)
    $pipe_writer.AutoFlush = $true
    return $pipe_server, $pipe_reader, $pipe_writer
}

function Start-NPipeClient ($pipe_name = "dev_env_pipe") {
    $pipe_client = New-Object IO.Pipes.NamedPipeClientStream(".", $pipe_name, [IO.Pipes.PipeDirection]::InOut,
            [IO.Pipes.PipeOptions]::None, [Security.Principal.TokenImpersonationLevel]::Impersonation)
    $pipe_client.Connect()
    $pipe_reader = New-Object IO.StreamReader($pipe_client)
    $pipe_writer = New-Object IO.StreamWriter($pipe_client)
    $pipe_writer.AutoFlush = $true
    return $pipe_client, $pipe_reader, $pipe_writer
}

function Write-Pipe ($pipe_writer, $var) {
    $type = $var.GetType().Name
    $pipe_writer.WriteLine($type)
    switch ($type) {
        "PSCustomObject" { $pipe_writer.WriteLine((ConvertTo-Json $var -Depth 10 -Compress)) }
        "Object[]" { $pipe_writer.WriteLine($var.Length) ; foreach ($v in $var) { $pipe_writer.WriteLine($v) } }
        Default { $pipe_writer.WriteLine($var) }
    }
}

function Read-Pipe ($pipe_reader) {
    $type = $pipe_reader.ReadLine()
    $var = $pipe_reader.ReadLine()
    switch ($type) {
        "PSCustomObject" { return ConvertFrom-Json $var }
        "Object[]" { $len = [int]$var ; $var = @() ; for ($i=0 ; $i -lt $len; $i+=1) { $var += $pipe_reader.ReadLine() } ; return $var }
        Default { return ($var -as $type) }
    }
}

function Send-Command ($pipe_writer, $cmd, $pkg) {
    Write-Pipe $pipe_writer $cmd
    Write-Pipe $pipe_writer $pkg
}

function Receive-Command ($pipe_reader) {
    $cmd = Read-Pipe $pipe_reader
    $pkg = Read-Pipe $pipe_reader
    return $cmd, $pkg
}

function Send-Output ($pipe_writer, $text) {
    Write-Pipe $pipe_writer "Write-Host"
    if ($text -is "ScriptBlock") { & $text } else { Write-Pipe $pipe_writer $text }
    Write-Pipe $pipe_writer "Write-Host:Done"
}

function Receive-Output ($pipe_reader) {
    $cmd = Read-Pipe $pipe_reader
    if ($cmd -eq "Write-Host") {
        while ($true) {
            $line = Read-Pipe $pipe_reader
            if ($line -eq "Write-Host:Done") { return $null, $null }
            $a = @() ; $o = @{} ; $arr = @($line)
            for ($i=0; $i -lt $arr.Length; $i+=1) {
                if ($arr[$i] -eq "-NoNewLine") {
                    $o[$arr[$i]] = $true
                } elseif ($arr[$i] -eq "-ForegroundColor" -and ($i+1) -lt $arr.Length) {
                    $o[$arr[$i]] = $arr[$i+1] ; $i+=1
                } else {
                    $a += $arr[$i]
                }
            }
            Write-Log $V_NORMAL @a @o
        }
    }
    $pkg = Read-Pipe $pipe_reader
    return $cmd, $pkg
}

$ps_elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function invoke ($cmd, $pkg, $pipe_reader, $pipe_writer) {
    if (-not $pkg.elevated -or $ps_elevated) {
        & $cmd $pkg
        return
    }
    # Send command to elevated shell
    Send-Command $pipe_writer $cmd $pkg
    $c, $p = Receive-Output $pipe_reader
    if ($null -ne $c) { throw "`nError: received unexpected command from elevated shell: '$c'" }
    Update-Env
}

function worker {
    try {
        # Init vars required for substitution
        $install_dir = $InstallDir
        $cache_dir = $CacheDir

        $pipe_client, $pipe_reader, $pipe_writer = Start-NPipeClient

        # Redirect log to pipe
        $log_output = { Write-Pipe $pipe_writer $_ }

        $worker_active = $true
        while ($worker_active) {
            $cmd, $pkg = Receive-Command $pipe_reader
            switch ($cmd) {
                "Install-Pkg"   { Send-Output $pipe_writer {Install-Pkg $pkg} }
                "Uninstall-Pkg" { Send-Output $pipe_writer {Uninstall-Pkg $pkg} }
                "Stop-Worker"   { $worker_active = $false}
                Default         { Send-Output $pipe_writer "Received unknown command: '$cmd'"}
            }
        }
    }
    catch {
        Write-Host $Error[0].ToString() -ForegroundColor Red
        exit 1
    }
    finally {
        $pipe_client.Dispose()
    }
}

function main {
    try {
        if ($Command.Trim().Length -lt 1) { throw "`nError: command is not specified" }

        Write-Log $V_NORMAL "Processing packages..."

        # Get config file
        $conf_file = $Config
        if (-not (Test-Path $conf_file)) { $conf_file = Join-Path $PSScriptRoot $conf_file }
        if (-not (Test-Path $conf_file)) { throw "ERROR: could not find '$Config', nothing to install." }

        # Parse JSON
        $conf = (Get-Content $conf_file) -join "" | ConvertFrom-Json

        # Init vars required for substitution
        $install_dir = Select-NonEmpty $InstallDir (Expand-String $conf.main.install_dir) -default 'C:\Dev\Tools'
        $cache_dir = Select-NonEmpty $CacheDir (Expand-String $conf.main.cache_dir) -default '.cache'
        Write-Log $V_HIGH "-- Install dir: $install_dir"
        Write-Log $V_HIGH "-- Cache dir: $cache_dir"

        # Get ordered package list
        $processed_list = @()
        $ordered_list = @()
        Get-PkgName $conf.main.kits $Kit | ForEach-Object {
            Get-PkgDependencies $conf.packages.$_ $_ ([ref]$processed_list) ([ref]$ordered_list)
        }

        # If there are packages that require elevation run elevated PS and setup client-server mode
        $pipe_server = $null
        $pipe_reader = $null
        $pipe_writer = $null
        foreach ($name in $ordered_list) {
            if ($conf.packages.$name.elevated -and !$ps_elevated) {
                Write-Log $V_QUIET "Some packages require Admin privileges to install, trying to elevate privileges..."
                $ps_args = "-File", $PSCommandPath, $Command, "-Config", $Config, "-Kit", $Kit, "-InstallDir", $install_dir, "-CacheDir", $cache_dir, "-DryRun", $DryRun, "-V", $V, "-WorkerMode", "-NonInteractive"
                $ps_obj = Start-Process powershell.exe $ps_args -WorkingDirectory $PWD -Verb RunAs -WindowStyle Hidden
                Start-Sleep -m 500
                if ($ps_obj.HasExited) { throw "`nError: could not run this script with elevated privileges`n" }
                $pipe_server, $pipe_reader, $pipe_writer = Start-NPipeServer
                break
            }
        }

        if ($Command -eq "install") {
            # Install packages listed in the kit
            foreach ($name in $ordered_list) { invoke Install-Pkg $conf.packages.$name $pipe_reader $pipe_writer }
        }
        elseif ($Command -eq "uninstall") {
            # Uninstall packages listed in the kit
            [array]::Reverse($ordered_list)
            foreach ($name in $ordered_list) { invoke Uninstall-Pkg $conf.packages.$name $pipe_reader $pipe_writer }
        }
        elseif ($Command -eq "update") {
            throw "`nNot implemented."
        }
        else {
            throw "`nError: unsupported command."
        }
    }
    catch {
        Write-Host $Error[0].ToString() -ForegroundColor Red
        exit 1
    }
    finally {
        if ($null -ne $pipe_server) {
            Send-Command $pipe_writer "Stop-Worker" "now"
            $pipe_server.Dispose()
        }
    }
}


if ($WorkerMode) {
    worker
} else {
    main
}
