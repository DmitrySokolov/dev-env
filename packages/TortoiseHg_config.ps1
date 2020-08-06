Add-PackageInfo `
    -Name "TortoiseHg_config" `
    -Description "Mercurial VCS config" `
    -Version "none" `
    -Platform "x86_64" `
    -DependsOn @("TortoiseHg") `
    -FindCmd {
        Test-Path $env:USERPROFILE\mercurial.ini -Type Leaf
    } `
    -InstallCmd {
        Set-Content -Path '$env:USERPROFILE/mercurial.ini' -Value @"
[ui]
username = $user_info
merge = kdiff3
editor = notepad

[extensions]
bugzilla =
color =
histedit =
purge =
rebase =
shelve =
strip =
mercurial_keyring =

[patch]
eol = auto

[tortoisehg]
tabwidth = 4
ui.language = en
autoresolve = False
postpull = update
graphopt = False
showfamilyline = True

[auth]
hg_server.prefix = foss.heptapod.net
hg_server.username = $user_name
hg_server.schemes = https

[merge-patterns]
**.doc = internal:prompt
**.rtf = internal:prompt
**.docx = internal:prompt
**.docm = internal:prompt
**.ods = internal:prompt
**.odt = internal:prompt
**.sxw = internal:prompt
**.xls = internal:prompt
**.xlsx = internal:prompt
**.exe = internal:prompt
**.dll = internal:prompt
**.lib = internal:prompt
**.pdb = internal:prompt
"@
    }
