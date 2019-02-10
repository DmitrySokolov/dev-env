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
    Optional, verbosity level. Default: "0".

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
        },
        "packages": {
            "pkg_ID": {
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

    "cache_dir" supports:
        * environment variables in format $env:VAR_NAME

    "install_cmd", "uninstall_cmd", "test_cmd" support:
        * environment variables in format $env:VAR_NAME
        * $install_dir - the directory name specified in -InstallDir param
        * $file_path - the full path of the package installer
        * $version - the value of the property Version of the current package
        * $($pkg.vars.xxx)
#>

# Command-line parameters
param (
    [string] $Command = $(throw "`nError: command is not specified"),
    [string] $Config = '.\config.json',
    [string] $Kit = 'default',
    [string] $InstallDir = '',
    [string] $CacheDir = '',
    [switch] $DryRun = $false,
    [int]    $V = 0
)

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

function Write-Host_IfVerbosity ($level) {
    if ($V -ge $level) {
        Write-Host @args
    }
}

function Invoke-Cmd {
    $cmd = $args -join ' '
    Write-Host $cmd
    if (!$DryRun) {
        $r = Invoke-Expression ($cmd + ' | Out-Default ; $?')
        if ($r -ne $true) { throw "`nError: command failed`n" }
    }
}

function Invoke-Test {
    $res = 'FAILED', 'OK'
    $clr = 'Yellow', 'Green'
    $cmd = $args -join ' '
    Write-Host_IfVerbosity 1 '-- Test : ' $cmd -NoNewLine
    $r = Invoke-Expression ($cmd + ' 2>&1 | Out-Null ; $?')
    Write-Host_IfVerbosity 1 ('  [{0}]' -f $res[[int]$r]) -ForegroundColor $clr[[int]$r]
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
        'notmatch' { return ($v -notmatch $value) }
    }
    return $true
}

function Get-PkgDescription ($pkg) {
    if ($pkg.version -ne "none") { return ("{0} v{1}" -f $pkg.description, $pkg.version) }
    return $pkg.description
}

function Update-PkgDependencies ($pkg, $action) {
    if ($pkg.depends_on.Length -lt 1) { return }
    $msg = @{   "install/meta:True"     = "-- Installing {0}";
                "install/meta:False"    = "-- Installing dependencies of {0}";
                "uninstall/meta:True"   = "-- Uninstalling {0}";
                "uninstall/meta:False"  = "-- Uninstalling dependencies of {0}"; }
    $cmd = @{   "install"   = "Install-Pkg";
                "uninstall" = "Uninstall-Pkg"; }
    Write-Host ($msg["{0}/meta:{1}" -f $action, ($pkg.install_cmd -eq "meta_pkg")] -f $pkg.description)
    foreach ($dep_name in $pkg.depends_on) {
        & $cmd[$action] $dep_name $conf.packages.$dep_name
    }
}

function Invoke-PkgCmd ($pkg, $pkg_cmd, $msg) {
    if ($pkg_cmd -match "meta_pkg|none") { return }
    # Init vars
    $file_name = $pkg.file_name
    if ($file_name -eq "from_url") { $file_name = $pkg.url -split "/" | Select-Object -Last 1 }
    $file_path = Join-Path $cache_dir $file_name
    $version = $pkg.version
    # Get package
    if ($pkg.url -ne "none") {
        if (Test-Path $file_path -PathType Leaf) {
            # Get package from cache
            Write-Host_IfVerbosity 1 "-- Found '$file_name' in cache"
        } else {
            # Download package
            Write-Host ("-- Downloading {0}" -f $pkg.url)
            Invoke-Cmd Invoke-WebRequest $pkg.url -OutFile $file_path
        }
    }
    # Invoke command
    Write-Host ($msg -f (Get-PkgDescription $pkg))
    Invoke-Cmd (Expand-String $pkg_cmd)
    Update-Env
}

function Install-Pkg ($name, $pkg) {
    # Check if package has been processed
    if ($installed -contains $name) { return }
    # Check if package already installed in OS
    if ($pkg.test_cmd -ne "none") {
        $r = Invoke-Test $pkg.test_cmd
        if ($r -eq $true) {
            Write-Host ("-- Found {0} installed" -f $pkg.description)
            $installed += $name
            return
        }
    }
    # Install requirements
    Update-PkgDependencies $pkg "install"
    # Install package
    Invoke-PkgCmd $pkg $pkg.install_cmd "-- Installing {0}"
    $installed += $name
}

function Uninstall-Pkg ($name, $pkg) {
    # Check if package has been processed
    if ($uninstalled -contains $name) { return }
    # Uninstall requirements
    Update-PkgDependencies $pkg "uninstall"
    # Uninstall package
    Invoke-PkgCmd $pkg $pkg.uninstall_cmd "-- Uninstalling {0}"
    $uninstalled += $name
}

try {
    Write-Host "Processing packages..."

    # Get config file
    $conf_file = $Config
    if (-not (Test-Path $conf_file)) { $conf_file = Join-Path $PSScriptRoot $conf_file }
    if (-not (Test-Path $conf_file)) { throw "ERROR: could not find '$Config', nothing to install." }

    # Parse JSON
    $conf = (Get-Content $conf_file) -join "" | ConvertFrom-Json

    $install_dir = Select-NonEmpty $InstallDir (Expand-String $conf.main.install_dir) -default 'C:\Dev\Tools'
    $cache_dir = Select-NonEmpty $CacheDir (Expand-String $conf.main.cache_dir) -default '.cache'
    Write-Host_IfVerbosity 1 "-- Install dir: $install_dir"
    Write-Host_IfVerbosity 1 "-- Cache dir: $cache_dir"

    if ($Command -eq "install") {
        # Install packages listed in the kit
        $installed = @()
        foreach ($name in $conf.main.kits.$Kit) {
            Install-Pkg $name $conf.packages.$name
        }
    }
    elseif ($Command -eq "uninstall") {
        # Uninstall packages listed in the kit
        $uninstalled = @()
        foreach ($name in $conf.main.kits.$Kit) {
            Uninstall-Pkg $name $conf.packages.$name
        }
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
