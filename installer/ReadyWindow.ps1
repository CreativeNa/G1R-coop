# The small "READY - waiting for your friend" window of the host. Started by CoopLauncher.ps1; the texts and the log path arrive in
# environment variables of that one process (G1R_READY_TEXT, G1R_JOINED_TEXT, G1R_CLOSE_TEXT, G1R_LOG_PATH), so no script file is
# generated and run from the temp folder and nothing has to be quoted on a command line.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$readyText = $env:G1R_READY_TEXT; $joinedText = $env:G1R_JOINED_TEXT; $closeText = $env:G1R_CLOSE_TEXT; $logPath = $env:G1R_LOG_PATH
if (-not $readyText) { $readyText = 'READY: waiting for your friend...' }
if (-not $joinedText) { $joinedText = 'Your friend is connected.' }
if (-not $closeText) { $closeText = 'Close' }
$f = New-Object Windows.Forms.Form
$f.Text = 'Gothic 1 Remake - co-op'
$f.Size = New-Object Drawing.Size(430, 125)
$f.TopMost = $true
$f.StartPosition = 'CenterScreen'
$l = New-Object Windows.Forms.Label
$l.Text = $readyText
$l.Font = New-Object Drawing.Font('Segoe UI', 11)
$l.AutoSize = $false
$l.Size = New-Object Drawing.Size(395, 45)
$l.Location = New-Object Drawing.Point(12, 12)
$f.Controls.Add($l)
$b = New-Object Windows.Forms.Button
$b.Text = $closeText
$b.Size = New-Object Drawing.Size(110, 28)
$b.Location = New-Object Drawing.Point(300, 48)
$b.Add_Click({ $f.Close() })
$f.Controls.Add($b)
$t = New-Object Windows.Forms.Timer
$t.Interval = 1000
$t.Add_Tick({
    try {
        if ($logPath -and (Test-Path -LiteralPath $logPath)) {
            $tail = Get-Content -LiteralPath $logPath -Tail 100 -ErrorAction SilentlyContinue
            if ($tail -match 'contact 1') { $l.Text = $joinedText; $l.ForeColor = [Drawing.Color]::DarkGreen; $t.Stop(); $c = New-Object Windows.Forms.Timer; $c.Interval = 5000; $c.Add_Tick({ $c.Stop(); $f.Close() }); $c.Start() }
        }
    } catch { }
})
$t.Start()
[void]$f.ShowDialog()
