param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Path,

    [Parameter(Mandatory=$false, Position=1)]
    [switch] $Recurse
)

$splat = @{
    Path = $Path
    Force = $true
}

if ($Recurse) {
    $splat.Add('Recurse', $true)
}

try {
    Remove-Item @splat -ErrorAction Stop
} catch {
    Write-Host "[-] Error removing path: $Path"
    Write-Host "[-] Error: $($_.Exception.Message)"
    return
}