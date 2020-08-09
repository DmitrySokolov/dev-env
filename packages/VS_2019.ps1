Add-PackageInfo `
    -Name "VS_2019" `
    -Description "Visual Studio Community 2019" `
    -Version "none" `
    -Platform "x86_64" `
    -Url "https://download.visualstudio.microsoft.com/download/pr/584a5fcf-dd07-4c36-add9-620e858c9a35/d7fe90b28d868706552a6d98ab8c8753e399dfa95753a1281ff388b691ab5465/vs_Community.exe" `
    -FileName "from_url" `
    -DependsOn @("Env_config") `
    -RequiresElevatedPS $true `
    -FindCmd {
        Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019" -Type Container
    } `
    -InstallCmd {
        & $Pkg.Installer --passive --wait --norestart `
            --layout "$cache_dir\vs_2019_offline_cache" `
            --add Microsoft.Component.MSBuild `
            --add Microsoft.VisualStudio.Component.IntelliCode `
            --add Microsoft.VisualStudio.Component.Roslyn.Compiler `
            --add Microsoft.VisualStudio.Component.Roslyn.LanguageServices `
            --add Microsoft.Net.Component.4.8.SDK `
            --add Microsoft.Net.Component.4.8.TargetingPack `
            --add Microsoft.Net.Component.4.7.TargetingPack `
            --add Microsoft.Net.ComponentGroup.4.8.DeveloperTools `
            --add Microsoft.VisualStudio.Component.VC.CoreIde `
            --add Microsoft.VisualStudio.Component.VC.DiagnosticTools `
            --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest `
            --add Microsoft.VisualStudio.Component.VC.CMake.Project `
            --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            --add Microsoft.VisualStudio.Component.VC.ATL `
            --add Microsoft.VisualStudio.Component.VC.ATLMFC `
            --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 `
            --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 `
            --add Microsoft.VisualStudio.Component.VC.v141.ATL `
            --add Microsoft.VisualStudio.Component.VC.v141.MFC `
            --add Microsoft.VisualStudio.Component.Windows10SDK `
            --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
            --add Microsoft.VisualStudio.Component.VC.Llvm.Clan `
            --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset `
            --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Llvm.Clang `
            --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core `
            | Out-Default
    } `
    -UninstallCmd {
        & $Pkg.Installer uninstall --passive --wait --norestart --all | Out-Default
    }
