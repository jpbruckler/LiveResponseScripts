

$DFIR_DIR   = '\\svr-w10-fsync01\dfir'
$TOOLS_DIR  = '\\svr-w10-fsync01\dfir\tools'

function Write-Console {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Message,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateSet('info', 'warning', 'error')]
        [string] $Level = 'info'
    )

    $status = @{
        info    = '[+]'
        warning = '[!]'
        error   = '[x]'
    }

    Write-Host "$($status[$Level]) $Message"
} #endwriteconsole

if ([string]::IsNullOrWhiteSpace($args[0]) -or ($args[0] -match 'help')) {
    Write-Host ""
    Write-Host "Invoke-KapeCollection.ps1"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "`t run Invoke-KapeCollection.ps1 <targets> [help]"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "`t - Comma separated list KAPE targets to collect. See below for options."
    Write-Host "`t - 'help' display this help message."
    Write-Host ""
    Write-Host "`t - A list of supported targets can be found here:"
    Write-Host "`t`t https://github.com/EricZimmerman/KapeFiles/tree/master/Targets"
    Write-Host ""
    Write-Host "`t - Target Bundles are Predefined KAPE targets bundled into a single"
    Write-Host "`t    target name. A list of supported target bundles are listed below."
    Write-Host ""
    Write-Host "Target Bundles:"
    Write-Host "`t BasicCollection"
    Write-Host "`t SANS_Triage"
    Write-Host "`t Antivirus"
    Write-Host "`t CloudStorage_All"
    Write-Host "`t CloudStorage_Metadata"
    Write-Host "`t CloudStorage_OneDriveExplorer"
    Write-Host "`t CombinedLogs"
    Write-Host "`t EvidenceOfExecution"
    Write-Host "`t Exchange"
    Write-Host "`t FileExplorerReplacements"
    Write-Host "`t FileSystem"
    Write-Host "`t FTPClients"
    Write-Host "`t IRCClients"
    Write-Host "`t KapeTriage"
    Write-Host "`t MessagingClients"
    Write-Host "`t MiniTimelineCollection"
    Write-Host "`t P2PClients"
    Write-Host "`t RecycleBin"
    Write-Host "`t RegistryHives"
    Write-Host "`t RemoteAdmin"
    Write-Host "`t ServerTriage"
    Write-Host "`t SOFELK"
    Write-Host "`t SQLiteDatabases"
    Write-Host "`t TorrentClients"
    Write-Host "`t USBDetective"
    Write-Host "`t UsenetClients"
    Write-Host "`t VirtualBox"
    Write-Host "`t VMware"
    Write-Host "`t WebBrowsers"
    Write-Host "`t WebServers"
    Write-Host "`t WSL"
    Write-Host ""
    Write-Host "Example: Collect FileSystem and RegistryHives targets"
    Write-Host "`t Invoke-KapeCollection.ps1 FileSystem,RegistryHives"
    Write-Host ""
    Write-Host "Example: Collect the SANS_Triage bundle"
    Write-Host "`t Invoke-KapeCollection.ps1 -TargetBundle SANS_Triage"
    Write-Host ""
    Write-Host "Once collection is complete, a zip file will be created in the DFIR share."
    exit
}
else {
    $allTargets   = $args[0].Split(',')

    for ($i = 0; $i -lt $allTargets.Count; $i++) {
        $allTargets[$i] = $allTargets[$i].Trim()
        if ($allTargets[$i] -in ('SANS_Triage', 'BasicCollection')) {
            Write-Console "Target $($allTargets[$i]) is a bundle. Expanding..."
            $allTargets[$i] = '!' + $allTargets[$i]
        }
    }
    $kapeZip        = "$TOOLS_DIR.zip"
    $expandDir      = "$env:PUBLIC\KAPE"
    $targetSource   = $env:SystemDrive
    $targetDest     = "$expandDir\collection"

    if (Test-Path $expandDir) {
        Write-Console "Removing existing KAPE directory..."
        Remove-Item -Path $expandDir -Recurse -Force
    }

    if (-not (Test-Path $kapeZip)) {
        Write-Console "KAPE.zip not found on DFIR share." 'error'
        Write-Console "Exiting..." 'error'
        exit
    }
    else {
        Write-Console "KAPE.zip found. Expanding to $expandDir"
        expand-archive -Path $kapeZip -DestinationPath $expandDir -Force
        $null = New-Item -Path $targetDest -ItemType Directory -Force

        Write-Console "Copying 7z.e $expandDir"
        Copy-Item -Path "$TOOLS_DIR estination $expandDir -Force
        Copy-Item -Path "$TOOLS_DIR estination $expandDir -Force
        Copy-Item -Path "$TOOLS_DIRp.dll" -Destination $expandDir -Force

        Write-Console "Setting KAPE working directory to $expandDir"
        Set-Location -Path $expandDir
        Write-Console "Starting KAPE collection..."
        Write-Console "Running command: .\kape.exe --tsource $targetSource --tdest $targetDest --tflush --target $allTargets"
        & .\kape.exe --tsource $targetSource --tdest $targetDest --tflush --target $allTargets
    }

    if ((Get-ChildItem $targetDest -File | Measure-Object).Count -gt 0) {
        Write-Console "KAPE collection complete. Zipping collection..."
        $zipFile = "$DFIR_DIR\$($env:COMPUTERNAME)\$(Get-Date -F 'yyyy-MM-ddTHH.mm.ss').7z"

        $null = New-Item -Path (Split-Path $zipFile -Parent) -ItemType Directory -Force

        Write-Console "Running command: .\7z.exe a -t7z -mx=1  -ms=on $zipFile $targetDest"
        & .\7z.exe a -t7z -mx=9 -m0=lzma2 -mfb=64 -md=32m -ms=on $zipFile $targetDest
        
        Write-Console "Collection zipped to $zipFile"
        Set-Location -Path $env:SystemDrive
        Write-Console "Cleaning up raw collection and KAPE files..."
        Remove-Item -Path "$expandDir\collection" -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Console "No files collected. Exiting..." 'warning'
    }
} #endelse