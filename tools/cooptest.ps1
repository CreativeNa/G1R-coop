# Online co-op test harness: the peer is a second PC, not a second process.
#
# The existing suites (parity_suite.ps1, scenarios.ps1, check.ps1) compare two copies running on ONE machine: they read
# the local log only. A real session has two machines, so this harness takes the host's log locally, pulls the guest's
# log through the diagnostic bridge (tools/diag_link.ps1, the guest runs `serve`), and runs the same checks against both.
#
#   .\tools\cooptest.ps1 -Peer x.x.x.x                 # invariants on both copies (about 10 s)
#   .\tools\cooptest.ps1 -Peer x.x.x.x -Mode Run       # guided scenarios: it tells you what to do, then verifies
#   .\tools\cooptest.ps1 -Mode Check                       # host only (guest checks are reported as SKIP)
#   .\tools\cooptest.ps1 -Peer ... -Mode Run -Only trade,sleep
#
# Exit code: 0 = everything passed, 1 = a check failed, 2 = no game running.
#
# Every run writes a report to docs\reports\online_<stamp>.md with the evidence (the log line that proved a check), so a
# session can be handed over without copying text by hand.
param(
    [string]$Peer = '',
    [ValidateSet('Check', 'Run', 'List')][string]$Mode = 'Check',
    [string[]]$Only = @(),
    [int]$Port = 40004,
    [string]$Token = '',
    [string]$OutDir = '',
    [switch]$KeepJson,
    [int]$Timeout = 40,
    [string]$HostLog = '',
    [string]$GuestReport = '',
    [switch]$Auto
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'docs\reports' }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$results = New-Object System.Collections.ArrayList

# ------------------------------------------------------------------ data
function Read-LocalLog {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'),
        (Join-Path $root 'native\build\coopdll.log')
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return @(Get-Content -LiteralPath $c -Tail 6000) } }
    return @()
}

function Read-Peer {
    # Returns @{ Ok; Log; Modules; Time; Settings; Json }
    if ($GuestReport) {
        # offline: analyse a report the bridge saved earlier, no network needed
        if (-not (Test-Path -LiteralPath $GuestReport)) { return @{ Ok = $false; Log = @(); Why = 'guest report not found' } }
        $j = Get-Content -LiteralPath $GuestReport -Raw | ConvertFrom-Json
        $log = @(); if ($j.coopdll_log) { $log = @($j.coopdll_log -split "`r?`n") }
        return @{ Ok = $true; Log = $log; Modules = $j.modules; Time = $j.time; Settings = $j.settings; File = $GuestReport; Why = ''; Processes = $j.processes }
    }
    if (-not $Peer) { return @{ Ok = $false; Log = @(); Why = 'no -Peer given' } }
    $link = Join-Path $PSScriptRoot 'diag_link.ps1'
    if (-not (Test-Path -LiteralPath $link)) { return @{ Ok = $false; Log = @(); Why = 'tools\diag_link.ps1 missing' } }
    $before = @(Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    try {
        # 2000 lines was the default and it once produced "no 'S role guest' line" on a copy that was fine: the role line
        # goes out every 10 s, but a busy log (diagnostics, item scans) can swallow 2000 lines in a few minutes.
        & $link fetch -Peer $Peer -Port $Port -Token $Token -LogLines 6000 | Out-Null
    } catch {
        return @{ Ok = $false; Log = @(); Why = "bridge failed: $($_.Exception.Message)" }
    }
    $all = @(Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime)
    $fresh = $all | Where-Object { $before -notcontains $_.Name } | Select-Object -Last 1
    if (-not $fresh) { $fresh = $all | Select-Object -Last 1 }
    if (-not $fresh) { return @{ Ok = $false; Log = @(); Why = 'the bridge answered nothing' } }
    try { $j = Get-Content -LiteralPath $fresh.FullName -Raw | ConvertFrom-Json } catch {
        return @{ Ok = $false; Log = @(); Why = 'the bridge answer is not JSON' }
    }
    if (-not $KeepJson) { }
    $log = @()
    if ($j.coopdll_log) { $log = @($j.coopdll_log -split "`r?`n") }
    return @{ Ok = $true; Log = $log; Modules = $j.modules; Time = $j.time; Settings = $j.settings; File = $fresh.FullName; Why = ''; Processes = $j.processes }
}

function Seat([string]$text) {
    if ($text -match 'ХОСТ|HOST') { return 'host' }
    if ($text -match 'ГОСТЬ|GUEST') { return 'guest' }
    return '?'
}

function Find-Lines($lines, [string]$pattern, [int]$max = 200) {
    # Always returns an array, even for one hit: a bare "return @(...)" let PowerShell unwrap a single element into a
    # string, and then $x[-1] took the last CHARACTER of the log line instead of the line itself.
    if (-not $lines) { return , @() }
    $hits = @($lines | Where-Object { $_ -match $pattern } | Select-Object -Last $max)
    return , $hits
}

function Check([string]$name, [string]$result, [string]$detail, [string]$evidence = '') {
    [void]$results.Add([pscustomobject]@{ Check = $name; Result = $result; Detail = $detail; Evidence = $evidence })
    $colour = switch ($result) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'DarkGray' } }
    Write-Host ('{0,-5} {1,-34} {2}' -f $result, $name, $detail) -ForegroundColor $colour
    if ($evidence -and $result -ne 'PASS') { Write-Host ("        " + $evidence) -ForegroundColor DarkGray }
}

function Pass($n, $d = '', $e = '') { Check $n 'PASS' $d $e }
function Fail($n, $d = '', $e = '') { Check $n 'FAIL' $d $e }
function Warn($n, $d = '', $e = '') { Check $n 'WARN' $d $e }
function Skip($n, $d = '') { Check $n 'SKIP' $d }

# ------------------------------------------------------------------ invariants
function Invoke-Invariants($hside, $gside) {
    $hostLog = $hside.Log; $guestLog = $gside.Log

    # running copies
    $procs = @(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)
    if ($procs.Count -ge 1) {
        $titles = ($procs | ForEach-Object { "$(Seat $_.MainWindowTitle) $($_.Id)" }) -join ', '
        Pass 'host copy running' $titles
    } elseif ($hside.Offline) { Skip 'host copy running' 'offline analysis of a saved log' }
    else { Fail 'host copy running' 'no G1R-Win64-Shipping process' }
    if ($gside.Ok) { Pass 'guest reachable' "bridge answered ($(Split-Path -Leaf $gside.File))" }
    else { Skip 'guest reachable' $gside.Why }

    # versions must match: every protocol change broke a session where they did not
    $hm = $hside.Modules; $gm = $gside.Modules
    if ($hm -and $gm) {
        # Compare CONTENT, not timestamps: an installer copies the files and every copy gets a new write time, so equal
        # timestamps never happen even for identical builds. A hash is the only honest comparison; the bridge sends one,
        # and the size is the fallback for a bridge that predates it.
        $hmap = @{}; foreach ($m in $hm) { $hmap[$m.name] = $m }
        $different = @(); $same = 0
        foreach ($m in $gm) {
            if (-not $hmap.ContainsKey($m.name)) { $different += "$($m.name) missing on the host"; continue }
            $h = $hmap[$m.name]
            $hs = $h.sha; $gs = $m.sha
            $sameContent = $false
            if ($hs -and $gs) { $sameContent = ($hs -eq $gs) }
            elseif ($h.size -and $m.size) { $sameContent = ($h.size -eq $m.size) }
            else { $sameContent = ($h.time -eq $m.time) }
            if ($sameContent) { $same++ }
            else { $different += "$($m.name) host=$($h.size)B/$hs guest=$($m.size)B/$gs" }
        }
        if ($different.Count -eq 0) { Pass 'module versions match' "$same modules identical by content" }
        else { Fail 'module versions match' ($different -join '; ') }
    } elseif ($gside.Ok) { Skip 'module versions match' 'module list not in the report' }

    # exceptions
    $he = Find-Lines $hostLog 'EXCEPTION'
    if ($he.Count -eq 0) { Pass 'host has no exceptions' '' }
    else { Fail 'host has no exceptions' "$($he.Count) in the log tail" $he[-1] }
    if ($gside.Ok) {
        $ge = Find-Lines $guestLog 'EXCEPTION'
        if ($ge.Count -eq 0) { Pass 'guest has no exceptions' '' }
        else { Fail 'guest has no exceptions' "$($ge.Count) in the log tail" $ge[-1] }
    } else { Skip 'guest has no exceptions' 'no peer' }

    # roles: a guest that thinks it is the host pulled the clock apart once already.
    # The window title is the more reliable witness: the module writes the seat into it on every frame, while the "S role"
    # line goes out every 10 s and a busy log can push it out of the tail (that is what made this check red at 14:13 when
    # nothing was wrong).
    $hr = Find-Lines $hostLog 'S role host' 1
    if ($hr.Count) { Pass 'host says it is the host' '' $hr[-1] } else { Fail 'host says it is the host' 'no "S role host" line' }
    if ($gside.Ok) {
        $gr = Find-Lines $guestLog 'S role guest' 1
        $wrong = Find-Lines $guestLog 'S role host' 1
        $gtitles = @(); if ($gside.Processes) { $gtitles = @($gside.Processes | ForEach-Object { "$($_.title)" }) }
        $guestTitle = @($gtitles | Where-Object { $_ -match 'ГОСТЬ|GUEST' }).Count -gt 0
        if ($wrong.Count) { Fail 'guest says it is the guest' 'the guest believes it is the host' }
        elseif ($gr.Count -and $guestTitle) { Pass 'guest says it is the guest' 'log and window title agree' $gr[-1] }
        elseif ($guestTitle) { Pass 'guest says it is the guest' 'window title says GUEST (no "S role guest" in the tail)' ($gtitles -join '; ') }
        else { Fail 'guest says it is the guest' ($(if ($gr.Count) { 'the log says guest but the window title does not' } else { 'neither the log tail nor the window title says guest' })) }
    }

    # the two copies see each other
    $hc = Find-Lines $hostLog 'contact 1' 1
    # A "contact 1" line anywhere in the tail proves nothing: it can be an hour old, and this check passed while the
    # window title already said "link lost" on 2026-11-07 18:39. Only the last two minutes count.
    $hcRecent = @(Lines-Since $hostLog ((Get-Date).AddSeconds(-120)) | Where-Object { $_ -match 'contact 1' })
    if ($hcRecent.Count) { Pass 'host has contact' "$($hcRecent.Count) recent line(s)" $hcRecent[-1] }
    elseif ($hc.Count) { Warn 'host has contact' 'the last "contact 1" is older than 2 minutes - the friend is probably gone' $hc[-1] }
    else { Warn 'host has contact' 'no "contact 1" in the log tail' }

    # NPC bookkeeping: "missing" is not zero in a live session (NPCs that exist on one copy only, or that are not streamed
    # in), so the honest check is that the number is not GROWING across the log tail rather than that it is 0.
    function Missing-Trend($lines, $pattern) {
        $vals = @(); foreach ($l in $lines) { if ($l -match $pattern -and $l -match 'missing (\d+)') { $vals += [int]$Matches[1] } }
        if ($vals.Count -eq 0) { return $null }
        $first = $vals[0]; $last = $vals[-1]; $max = ($vals | Measure-Object -Maximum).Maximum
        return @{ First = $first; Last = $last; Max = $max; Line = ($lines | Where-Object { $_ -match $pattern })[-1] }
    }
    $ht = Missing-Trend $hostLog 'N seat 0:'
    if ($ht) {
        $grew = $ht.Last - $ht.First
        if ($grew -le 1) { Pass 'host knows its NPCs' "missing $($ht.Last) (was $($ht.First), max $($ht.Max)) - not growing" $ht.Line }
        else { Warn 'host knows its NPCs' "missing grew by $grew ($($ht.First) -> $($ht.Last))" $ht.Line }
    } else { Skip 'host knows its NPCs' 'no "N seat 0:" line' }
    if ($gside.Ok) {
        $gt = Missing-Trend $guestLog 'N seat 1:'
        if ($gt) {
            $grew = $gt.Last - $gt.First
            if ($grew -le 1) { Pass 'guest knows its NPCs' "missing $($gt.Last) (was $($gt.First), max $($gt.Max)) - not growing" $gt.Line }
            else { Warn 'guest knows its NPCs' "missing grew by $grew ($($gt.First) -> $($gt.Last))" $gt.Line }
        } else { Skip 'guest knows its NPCs' 'no "N seat 1:" line' }
    }

    # performance: the frame budget is the thing players feel
    $cost = Find-Lines $hostLog 'M cost ms' 1
    if ($cost.Count) {
        $line = $cost[-1]; $total = 0.0
        foreach ($m in [regex]::Matches($line, '(anim|equip|pose|npc|story|menu|probe)\s+([\d.,]+)/')) {
            $total += [double](($m.Groups[2].Value) -replace ',', '.')
        }
        if ($total -le 0) { $total = -1 }
        if ($total -lt 0) { Skip 'frame cost' 'the cost line could not be parsed' }
        elseif ($total -lt 4.0) { Pass 'frame cost' ("{0:N2} ms per frame" -f $total) $line }
        elseif ($total -lt 7.0) { Warn 'frame cost' ("{0:N2} ms per frame" -f $total) $line }
        else { Fail 'frame cost' ("{0:N2} ms per frame" -f $total) $line }
    } else { Skip 'frame cost' 'no "M cost ms" line' }
    $slow = @($hostLog | Select-Object -Last 600 | Where-Object { $_ -match 'S slowfn' })
    if ($slow.Count -eq 0) { Pass 'no slow calls' '' }
    else { Warn 'no slow calls' "$($slow.Count) calls above 6 ms in the tail" $slow[-1] }

    # log hygiene (12A): the npc module used to write per-second rig diagnostics without any switch - 13 MB of log an
    # hour, one obj_name per line. They are gated behind npc_diag.txt now, so their presence means the switch is on.
    # only the last two minutes: the tail still holds the diagnostics from before npc_diag.txt existed, and a check that
    # keeps reporting them can never go green again
    $recent = Lines-Since $hostLog ((Get-Date).AddSeconds(-120))
    $diag = @($recent | Where-Object { $_ -match 'N diag nearest NPC|N diag mirror rig|N diag guest mirror|N rig .*actor yaw' })
    if ($diag.Count -eq 0) { Pass 'rig diagnostics quiet' 'no per-second rig lines in the tail' }
    else { Warn 'rig diagnostics quiet' "$($diag.Count) diagnostic lines in the tail - npc_diag.txt is on" $diag[-1] }
    if ($gside.Ok) {
        $recentG = Lines-Since $gside.Log ((Get-Date).AddSeconds(-120))
        $diagG = @($recentG | Where-Object { $_ -match 'N diag nearest NPC|N diag mirror rig|N diag guest mirror|N rig .*actor yaw' })
        if ($diagG.Count -eq 0) { Pass 'guest rig diagnostics quiet' 'no per-second rig lines in the guest tail' }
        else { Warn 'guest rig diagnostics quiet' "$($diagG.Count) diagnostic lines - npc_diag.txt is on there too" $diagG[-1] }
    }
    $lp = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'
    if ((Test-Path -LiteralPath $lp) -and -not $hside.Offline) {
        $mb = [math]::Round((Get-Item -LiteralPath $lp).Length / 1MB, 1)
        if ($mb -lt 50) { Pass 'log size' "$mb MB" } else { Warn 'log size' "$mb MB - the log is appended across sessions, check what writes it" }
    }

    $fps = Find-Lines $hostLog 'PR fps' 1
    if ($fps.Count) {
        $line = $fps[-1]; $v = 0
        if ($line -match 'PR fps ([\d.,]+)') { $v = [double](($Matches[1]) -replace ',', '.') }
        if ($v -le 0) { Skip 'host frame rate' 'the fps line could not be parsed' }
        elseif ($v -ge 25) { Pass 'host frame rate' "$v fps" $line } else { Warn 'host frame rate' "$v fps" $line }
    }
}

# ------------------------------------------------------------------ scenarios
# Each scenario: what the two players do, and the log lines that prove it happened. A check is evaluated only on lines
# that arrived after the scenario started, so an old pass cannot count for a new attempt.
$scenarios = @(
    @{ Id = 'connect'; Title = 'Connection and roles';
       Steps = @('Restart both games (host first), wait until the guest sees "welcome, the gate is open".');
       Wait = 25
       Checks = @(
           @{ Side = 'host'; Name = 'host handshake'; Pattern = 'welcome, the gate is open' },
           @{ Side = 'guest'; Name = 'guest handshake'; Pattern = 'welcome, the gate is open' },
           @{ Side = 'guest'; Name = 'guest reports the guest role'; Pattern = 'S role guest' }
       ) }
    @{ Id = 'clock'; Title = 'One clock';
       Steps = @('Type the time cheat on the host: set build\cheat_time_h.txt to "8:00".', 'Wait 10 s, then set it to "?" on both copies.');
       Wait = 25
       Checks = @(
           @{ Side = 'host'; Name = 'host sets its clock'; Pattern = 'S time set: 08:00 here' },
           @{ Side = 'guest'; Name = 'guest followed the clock'; Pattern = 'S time: clock set to 08:0' }
       ) }
    @{ Id = 'npc'; Title = 'NPC mirroring';
       Steps = @('Walk together to a guard, stand 3-5 m from him for 10 s, then walk away and back.');
       Wait = 30
       Checks = @(
           @{ Side = 'host'; Name = 'host simulates an NPC'; Pattern = 'N seat 0: .*simulating [1-9]' },
           @{ Side = 'guest'; Name = 'guest mirrors an NPC'; Pattern = 'N seat 1: .*mirroring [1-9]|N seat 1: .*simulating [1-9]' },
           @{ Side = 'guest'; Name = 'guest NPC bookkeeping is sane'; Pattern = 'N seat 1: .*missing [0-3]\b' }
       ) }
    @{ Id = 'items'; Title = 'Loose items travel';
       Steps = @('The guest picks up any world item (ore, food) while the host stands 5 m away.');
       Wait = 20
       Checks = @(
           @{ Side = 'guest'; Name = 'guest tracked the pickup'; Pattern = 'S item .*picked up here' },
           @{ Side = 'host'; Name = 'host removed it'; Pattern = 'S gone received: .*\(tracked here\)|S item .*removed on arrival|S item .*the other player picked it up' }
       ) }
    @{ Id = 'chest'; Title = 'Chests and the in-use lock';
       Steps = @('The guest opens a chest and puts one item in.', 'The host walks up to the same chest while the guest is still in it.');
       Wait = 30
       Checks = @(
           @{ Side = 'guest'; Name = 'guest used the chest'; Pattern = 'S chest .*in use 1' },
           @{ Side = 'host'; Name = 'host saw the lock or the content'; Pattern = 'S chest .*in use 1 \(sent\)|S chest .*in use 1 by the other player|S chest .*emptied on arrival|S chest tracked' }
       ) }
    @{ Id = 'trade'; Title = 'Trader stock and purse';
       Steps = @('Both stand near Mordrag. The host opens the trade window and buys one cheap item.', 'Close the window and let the guest open the same trader.');
       Wait = 35
       Checks = @(
           @{ Side = 'host'; Name = 'host opened a trade'; Pattern = 'S trade lock: opened' },
           @{ Side = 'guest'; Name = 'guest got the trade notice'; Pattern = 'S trade notice: .*being traded with' },
           @{ Side = 'host'; Name = 'host sent the stock'; Pattern = 'S trade: stock changed, sent' },
           @{ Side = 'host'; Name = 'host listed its stock with fingerprints'; Pattern = 'S stock sent:' },
           @{ Side = 'guest'; Name = 'guest applied the stock'; Pattern = 'S trade: trader #\d+ (updated here|matched by item)' }
       ) }
    @{ Id = 'sleep'; Title = 'Shared sleep';
       Steps = @('The guest lies down in a bed and sleeps until morning.', 'Then the host does the same.');
       Wait = 40
       Checks = @(
           @{ Side = 'guest'; Name = 'guest slept'; Pattern = 'S sleep: the clock after sleeping is|S time: the clock jumped forward .*\(slept' },
           @{ Side = 'host'; Name = 'host went dark'; Pattern = 'S sleep: dark for|S sleep: the other player is getting into bed' },
           @{ Side = 'host'; Name = 'host took the new time'; Pattern = 'S sleep: the other player slept, the clock' },
           @{ Side = 'guest'; Name = 'no false dark screen while sitting'; Pattern = 'S sleep: dark for 2.00 s \(the other player is asleep\)' }
       ) }
    @{ Id = 'death'; Title = 'Shared death and load';
       Steps = @('Write "killme" to build\give_<side>.txt on the host.', 'When both lie dead, press "load last save" on the host.');
       Wait = 45
       Checks = @(
           @{ Side = 'host'; Name = 'host died'; Pattern = 'S death: this hero died|S give: killme' },
           @{ Side = 'guest'; Name = 'guest died too'; Pattern = 'S death: the friend died, this hero is killed too' },
           @{ Side = 'guest'; Name = 'guest loaded with the host'; Pattern = 'S load: the friend loaded the last save' },
           @{ Side = 'both'; Name = 'control came back (no UI lock)'; Pattern = 'S death screen: .*input mode|S load: a new hero' }
       ) }
    @{ Id = 'soak'; Title = 'Ten quiet minutes';
       Steps = @('Just play normally: walk, fight, loot.', 'Nobody touches the test aids.');
       Wait = 600
       Checks = @(
           @{ Side = 'both'; Name = 'no exceptions during the soak'; NotPattern = 'EXCEPTION' },
           @{ Side = 'host'; Name = 'NPC bookkeeping keeps reporting'; Pattern = 'N seat 0: .*characters known' }
       ) }
    @{ Id = 'trade_buyout'; Title = 'Trader stock: an item bought out disappears on the other copy';
       Steps = @('The guest opens Mordrag and buys the ENTIRE stack of one item (arrows are the usual victim).', 'Close the window, then reopen it: the stock must be the same on both copies.');
       Wait = 40
       Checks = @(
           @{ Side = 'guest'; Name = 'guest sent its stock'; Pattern = 'S trade: stock changed, sent' },
           @{ Side = 'host'; Name = 'host took the entries off the shelf'; Pattern = 'entries taken off the shelf' },
           @{ Side = 'host'; Name = 'host matched what it could'; Pattern = 'S trade: trader #\d+ matched by item: \d+ written' }
       ) }
    @{ Id = 'reconnect'; Title = 'The link drops and comes back';
       Steps = @('Set native\build\net_sim.txt to "loss=100" (or unplug the VPN) for 15-30 s.', 'Remove the file (or restore the VPN) and wait until the copy is back.');
       Wait = 60
       Checks = @(
           @{ Side = 'both'; Name = 'no exceptions while the link was down'; NotPattern = 'EXCEPTION' },
           @{ Side = 'host'; Name = 'host has contact again'; Pattern = 'contact 1' },
           @{ Side = 'host'; Name = 'frames keep running (no hang)'; Pattern = 'PR fps' }
       ) }
    @{ Id = 'reload_busy'; Title = 'A load while the other player is busy';
       Steps = @('The guest opens Mordrag and keeps the trade window open.', 'The host presses F9 (load last save) and waits for the world.');
       Wait = 90
       Checks = @(
           @{ Side = 'host'; Name = 'host loaded'; Pattern = 'S load: a new hero|S load: the last save' },
           @{ Side = 'guest'; Name = 'guest followed the load'; Pattern = 'S load: the friend loaded the last save' },
           @{ Side = 'both'; Name = 'no exceptions around the load'; NotPattern = 'EXCEPTION' }
       ) }
    @{ Id = 'pickup_both'; Title = 'Both players grab the same item';
       Steps = @('Drop one item on the ground in front of both heroes (test aid: "dropnear:ItMw_1H_Torch").', 'Both press the interact key at the same moment.');
       Wait = 30
       Checks = @(
           @{ Side = 'both'; Name = 'one copy reports the pickup'; Pattern = 'S item .*picked up here' },
           @{ Side = 'both'; Name = 'the other copy removed it'; Pattern = 'S gone received|removed on arrival|the other player picked it up' },
           @{ Side = 'both'; Name = 'no duplicate item left behind'; NotPattern = 'EXCEPTION' }
       ) }
)

# Log lines are stamped "[<pid> HH:MM:SS.mmm] text" (host and guest alike), so the scenario start is a TIME marker, not
# a line index. Index slicing was wrong: Read-LocalLog returns a tail capped at 6000 lines, the count therefore never
# grows, "count > base" stayed false and every scenario checked an EMPTY list - three checks failed at 15:37 on a run
# where the log plainly had the lines. A time marker also survives the tail sliding forward.
function Lines-Since($lines, [datetime]$since) {
    $out = @()
    if (-not $lines) { return , $out }
    foreach ($l in $lines) {
        if ($l -match '^\[\d+\s+(\d{2}):(\d{2}):(\d{2})\.(\d{3})\]') {
            $t = (Get-Date).Date.AddHours([int]$Matches[1]).AddMinutes([int]$Matches[2]).AddSeconds([int]$Matches[3]).AddMilliseconds([int]$Matches[4])
            if ($t -lt $since.AddHours(-12)) { $t = $t.AddDays(1) }          # a run across midnight, not "anything old"
            if ($t -ge $since) { $out += $l }
        }
    }
    return , $out
}

function Invoke-Scenario($s, $hside, $gside) {
    Write-Host ''
    Write-Host ("=== {0} — {1}" -f $s.Id, $s.Title) -ForegroundColor Cyan
    foreach ($line in $s.Steps) { Write-Host ("    " + $line) }
    if ($Auto) {
        # non-interactive: give the players the full window and just wait
        Write-Host ("    running the scenario for {0} s (-Auto)" -f $s.Wait) -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
        $t0 = (Get-Date).AddSeconds(-2)
        Start-Sleep -Seconds $s.Wait
        $waited = $s.Wait
    } else {
        Write-Host ''
        Write-Host ("    press Enter when you start, then do it, then press Enter again (waiting up to {0} s)" -f $s.Wait) -ForegroundColor DarkGray
        $null = Read-Host '    start'
        $t0 = (Get-Date).AddSeconds(-2)
        Write-Host '    ... performing' -ForegroundColor DarkGray
        $null = Read-Host '    done'
        $waited = [int]((Get-Date) - $t0).TotalSeconds
    }
    Start-Sleep -Seconds 3
    Write-Host ("    collecting the logs ({0} s of play)" -f $waited) -ForegroundColor DarkGray
    $h = Read-LocalLog
    $g = Read-Peer
    if (-not $g.Ok) { Warn ($s.Id + ' peer') $g.Why }
    # only the lines that arrived while the scenario ran: an old pass must never count for a new attempt
    $h = Lines-Since $h $t0
    if ($g.Ok) { $g.Log = Lines-Since $g.Log $t0 } else { $g = @{ Log = @(); Ok = $false } }

    foreach ($c in $s.Checks) {
        $sides = switch ($c.Side) { 'host' { @($h) } 'guest' { @($g.Log) } default { @($h) + @($g.Log) } }
        $ok = $false; $evidence = ''; $why = ''
        # A plain -match over the lines. The old form piped every line through Find-Lines, which returns a WRAPPED empty
        # array; the pipeline then handed back "one item" (that empty array), $hits.Count was 1 and a NotPattern check
        # failed with "found: " and no evidence - the ten-minute soak failed on 2026-11-07 exactly like that while both
        # logs had zero EXCEPTION lines.
        $pat = if ($c.NotPattern) { $c.NotPattern } else { $c.Pattern }
        $hits = @()
        foreach ($ln in $sides) { if ($ln -and $ln -match $pat) { $hits += $ln } }
        if ($c.NotPattern) {
            if ($hits.Count -eq 0) { $ok = $true } else { $why = "found: $($hits[0])" }
        } else {
            if ($hits.Count -gt 0) { $ok = $true; $evidence = $hits[-1] } else { $why = "no line matches /$($c.Pattern)/" }
        }
        if ($ok) { Pass ("$($s.Id): $($c.Name)") '' $evidence }
        else { Fail ("$($s.Id): $($c.Name)") $why }
    }
}

# ------------------------------------------------------------------ report
function Write-Report($hside, $gside) {
    $file = Join-Path $OutDir "online_$stamp.md"
    $pass = @($results | Where-Object { $_.Result -eq 'PASS' }).Count
    $fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
    $warn = @($results | Where-Object { $_.Result -eq 'WARN' }).Count
    $skip = @($results | Where-Object { $_.Result -eq 'SKIP' }).Count
    $verdict = if ($fail -eq 0 -and $warn -eq 0) { 'green' } elseif ($fail -eq 0) { 'green with warnings' } else { 'red' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Online co-op test — $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("* peer: $(if ($Peer) { $Peer } else { 'host only' })")
    [void]$sb.AppendLine("* mode: $Mode")
    [void]$sb.AppendLine("* verdict: **$verdict** ($pass passed, $fail failed, $warn warnings, $skip skipped)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| result | check | detail | evidence |')
    [void]$sb.AppendLine('|---|---|---|---|')
    foreach ($r in $results) {
        $ev = ($r.Evidence -replace '\|', '\|')
        if ($ev.Length -gt 160) { $ev = $ev.Substring(0, 160) + '…' }
        [void]$sb.AppendLine(('| {0} | {1} | {2} | `{3}` |' -f $r.Result, ($r.Check -replace '\|', '\|'), ($r.Detail -replace '\|', '\|'), $ev))
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('## What to do with a failure')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('Each row names the log line that should have appeared. The same check in `docs/BUGS.md` says what that')
    [void]$sb.AppendLine('line means and what the cause looked like the last time. If a check fails and the log has no such line at all,')
    [void]$sb.AppendLine('the feature never ran on that copy - that is the first thing to look at, not the sync.')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('## Evidence lines')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('```')
    if ($hside.Log) { [void]$sb.AppendLine('# host (last 8)'); $hside.Log | Select-Object -Last 8 | ForEach-Object { [void]$sb.AppendLine($_) } }
    if ($gside.Log) { [void]$sb.AppendLine('# guest (last 8)'); $gside.Log | Select-Object -Last 8 | ForEach-Object { [void]$sb.AppendLine($_) } }
    [void]$sb.AppendLine('```')
    Set-Content -LiteralPath $file -Value $sb.ToString() -Encoding utf8
    Write-Host ''
    Write-Host "report: $file"
    Write-Host "verdict: $verdict ($pass passed, $fail failed, $warn warnings, $skip skipped)"
    return [bool]($fail -eq 0)
}

# ------------------------------------------------------------------ main
if ($Mode -eq 'List') {
    foreach ($s in $scenarios) { "{0,-10} {1}" -f $s.Id, $s.Title }
    exit 0
}

$offline = ($HostLog -ne '' -or $GuestReport -ne '')
if (-not $offline -and -not (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)) {
    "no Gothic 1 Remake process is running - start the session first (or pass -HostLog / -GuestReport to analyse a saved log)"; exit 2
}

$hostData = @{ Ok = $true; Log = (Read-LocalLog); Modules = $null; File = 'local' ; Why = ''; Offline = $offline }
# the host's own module list, for the version comparison.
# Content, not timestamps: a deploy writes the same bytes twice with different write times (and the per-process copies
# in the same folder are a different thing entirely), so the digest is the only comparison that means anything.
$modDir = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\modules'
if (Test-Path -LiteralPath $modDir) {
    $hostData.Modules = @(Get-ChildItem -LiteralPath $modDir -Filter *.dll | Where-Object { $_.Name -notmatch '_\d+_\d+' } | ForEach-Object {
        $sha = try { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.Substring(0, 16) } catch { '' }
        @{ name = $_.Name; time = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'); size = $_.Length; sha = $sha } })
}
$guestData = Read-Peer

if ($Mode -eq 'Check') {
    Write-Host ''
    Write-Host '=== invariants (both copies) ===' -ForegroundColor Cyan
    Invoke-Invariants $hostData $guestData
    $ok = Write-Report $hostData $guestData
    if ($ok) { exit 0 } else { exit 1 }
}

if ($Mode -eq 'Run') {
    # NOTE: "$x = if (...) { @(...) }" lets PowerShell unwrap a one-element array into the hashtable itself, and then
    # $x[0] is $null. Assign inside the branches instead.
    if ($Only.Count) { $todo = @($scenarios | Where-Object { $Only -contains $_.Id }) } else { $todo = @($scenarios) }
    if (-not $todo.Count) { "no scenario matches $($Only -join ', ') - try -Mode List"; exit 1 }
    Write-Host ''
    Write-Host '=== online session scenarios ===' -ForegroundColor Cyan
    Write-Host '    two players needed: one on this PC (host), one on the peer.' -ForegroundColor DarkGray
    foreach ($s in $todo) { Invoke-Scenario $s $hostData $guestData | Out-Null }
    $ok = Write-Report $hostData $guestData
    if ($ok) { exit 0 } else { exit 1 }
}
