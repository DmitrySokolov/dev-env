Add-PackageInfo `
    -Name "VS_build_tools_2019" `
    -Description "Build Tools for Visual Studio 2019" `
    -Version "none" `
    -Platform "x86_64" `
    -Url "https://download.visualstudio.microsoft.com/download/pr/067fd8d0-753e-4161-8780-dfa3e577839e/91e449a6b736cda31d94613f6d88668825e8b0b43f8b041d22b3a3461b23767f/vs_BuildTools.exe" `
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
            --add Microsoft.VisualStudio.Component.CoreBuildTools `
            --add Microsoft.VisualStudio.Component.Roslyn.Compiler `
            --add Microsoft.Net.Component.4.8.SDK `
            --add Microsoft.Net.Component.4.8.TargetingPack `
            --add Microsoft.Net.Component.4.7.TargetingPack `
            --add Microsoft.Net.ComponentGroup.4.8.DeveloperTools `
            --add Microsoft.VisualStudio.Component.VC.CoreBuildTool `
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
            | Out-Default
    } `
    -UninstallCmd {
        & $Pkg.Installer uninstall --passive --wait --norestart --all | Out-Default
    }
