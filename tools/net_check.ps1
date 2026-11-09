# Checks the UDP path between the two PCs BEFORE the game is started, so a broken network shows up as a broken
# network instead of as "the friend is invisible".
#
#   host PC:  .\tools\net_check.ps1 -Role host
#   guest PC: .\tools\net_check.ps1 -Role guest -Peer <host IP or name>
#
# The host listens on -Port and answers every probe with a reply; the guest sends one probe a second and prints the
# answers. Both sides also print what to do when nothing arrives. Stop with Ctrl+C. The game must be closed: it
# holds the same port.
param(
    [Parameter(Mandatory = $true)][ValidateSet("host", "guest")][string]$Role,
    [string]$Peer = "",
    [int]$Port = 40001,
    [int]$Seconds = 120
)
$ErrorActionPreference = "Stop"
$tag = if ($Role -eq "host") { "HOST" } else { "GUEST" }

if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
    "a game copy is running and holds UDP $Port - close it first"; exit 1
}
if ($Role -eq "guest" -and -not $Peer) { "the guest needs -Peer <host IP or name>"; exit 1 }

"local addresses:"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } |
    ForEach-Object { "  {0,-16} {1}" -f $_.IPAddress, $_.InterfaceAlias }

function Show-FirewallHint {
    "nothing arrived. In this order:"
    "  1. on the HOST, allow the port once (run as administrator):"
    "       .\tools\firewall_coop.ps1 -Action add -Port $Port"
    "  2. on the GUEST, try the host's LAN/VPN address, not its public one"
    "  3. over the internet: forward UDP $Port on the host's router to the host PC"
    "  4. a VPN (Radmin/ZeroTier) removes both the router and the firewall question: both PCs join one network"
}

if ($Role -eq "host") {
    $udp = New-Object System.Net.Sockets.UdpClient($Port)
    "listening on UDP $Port for ${Seconds}s - start the guest now"
    $seen = @{}
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        if (-not $udp.Available) { Start-Sleep -Milliseconds 200; continue }
        $from = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $bytes = $udp.Receive([ref]$from)
        $text = [Text.Encoding]::ASCII.GetString($bytes)
        if ($text -ne "COOP-PING") { continue }
        $reply = [Text.Encoding]::ASCII.GetBytes("COOP-PONG")
        [void]$udp.Send($reply, $reply.Length, $from)
        $key = $from.ToString()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = 0
            "  <> contact from ${key} - the path works, answered"
        }
        $seen[$key]++
        if ($seen[$key] % 10 -eq 0) { "  <> ${key}: $($seen[$key]) probes answered" }
    }
    $udp.Close()
    if ($seen.Count -eq 0) { Show-FirewallHint } else { "done: $($seen.Count) peer(s) reached this PC" }
    exit 0
}

$client = New-Object System.Net.Sockets.UdpClient
$client.Client.ReceiveTimeout = 1000
$client.Connect($Peer, $Port)
"sending a probe to ${Peer}:${Port} once a second for ${Seconds}s"
$answers = 0
$deadline = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $deadline) {
    $probe = [Text.Encoding]::ASCII.GetBytes("COOP-PING")
    try { [void]$client.Send($probe, $probe.Length) } catch { "send failed: $($_.Exception.Message)"; break }
    try {
        $from = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $bytes = $client.Receive([ref]$from)
        $text = [Text.Encoding]::ASCII.GetString($bytes)
        if ($text -eq "COOP-PONG") {
            $answers++
            if ($answers -eq 1) { "  <> the host answered - the path works in both directions" }
            elseif ($answers % 10 -eq 0) { "  <> $answers answers" }
        }
    } catch { }
    Start-Sleep -Milliseconds 1000
}
$client.Close()
if ($answers -eq 0) { Show-FirewallHint; exit 1 }
"done: $answers answers from $Peer"
