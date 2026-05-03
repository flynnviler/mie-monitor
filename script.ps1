# =========================
# CONFIG (FROM ENV VARIABLES)
# =========================
$EmailTo       = $env:ALERT_EMAIL
$EmailSubject  = "🚨 MIE ePCV Monitor Alert"

$NodeScript    = $env:NODE_SCRIPT_PATH
$ScreenshotDir = $env:SCREENSHOT_DIR
$LogFile       = Join-Path $ScreenshotDir "failure-log.txt"

if (-not $EmailTo -or -not $NodeScript -or -not $ScreenshotDir) {
    Write-Host "❌ Missing required environment variables"
    exit 1
}

$run = 1
$LastReportTime = Get-Date
$ReportInterval = 3600   # 1 hour

# Ensure screenshot folder exists
if (!(Test-Path $ScreenshotDir)) {
    New-Item -ItemType Directory -Path $ScreenshotDir | Out-Null
}

while ($true) {

    Write-Host "==============================="
    Write-Host "Run #$run - Checking MIE..."
    Write-Host "==============================="

    # =========================
    # RUN NODE SCRIPT
    # =========================
    $output = node $NodeScript 2>&1
    Write-Host $output

    # =========================
    # PARSE RESULT
    # =========================
    $resultLine = $output | Select-String "RESULT:" | Select-Object -Last 1
    $messageLine = $output | Select-String "MESSAGE:" | Select-Object -Last 1

    $resultType = "UNKNOWN"
    $message = "No message returned"

    if ($resultLine) {
        $resultType = ($resultLine.Line -replace "RESULT:", "").Trim()
    }

    if ($messageLine) {
        $message = ($messageLine.Line -replace "MESSAGE:", "").Trim()
    }

    Write-Host "Result: $resultType"
    Write-Host "Message: $message"

    if ($resultType -eq "OK") {

        Write-Host "✔ LOGIN SUCCESSFUL - No email sent"

    } else {

        Write-Host "🚨 FAILURE DETECTED: $resultType"

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # LOG FAILURE
        Add-Content -Path $LogFile -Value "$timestamp | $resultType | $message"

        # Keep only last hour logs
        if (Test-Path $LogFile) {

            $cutoff = (Get-Date).AddHours(-1)

            $filtered = Get-Content $LogFile | Where-Object {

                if ($_ -match "^\d{4}-\d{2}-\d{2}") {
                    try {
                        $time = [datetime]::Parse($_.Split("|")[0].Trim())
                        return $time -gt $cutoff
                    } catch {
                        return $true
                    }
                }
                return $true
            }

            $filtered | Set-Content $LogFile
        }

        # GET LATEST SCREENSHOT
        $screenshot = Get-ChildItem $ScreenshotDir -Filter "*.png" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        # SEND EMAIL ALERT (OUTLOOK)
        $Outlook = New-Object -ComObject Outlook.Application
        $Mail = $Outlook.CreateItem(0)

        $Mail.To = $EmailTo
        $Mail.Subject = "$EmailSubject - $resultType (Run $run)"

        $body = @"
<html>
<body>
<h2>MIE ePCV ALERT</h2>
<p><b>Status:</b> $resultType</p>
<p><b>Message:</b> $message</p>
<p><b>Time:</b> $timestamp</p>
"@

        if ($screenshot) {

            $attachment = $Mail.Attachments.Add($screenshot.FullName)

            $cid = "MIEScreenshot"
            $attachment.PropertyAccessor.SetProperty(
                "http://schemas.microsoft.com/mapi/proptag/0x3712001F",
                $cid
            )

            $body += "<br><img src='cid:$cid' width='1200'>"
        }
        else {
            $body += "<p>No screenshot found</p>"
        }

        $body += "</body></html>"

        $Mail.HTMLBody = $body
        $Mail.Send()

        Write-Host "📧 ALERT EMAIL SENT"
    }

    # =========================
    # HOURLY SUMMARY
    # =========================
    if ((New-TimeSpan -Start $LastReportTime).TotalSeconds -ge $ReportInterval) {

        Write-Host "📊 Sending hourly summary..."

        $Outlook = New-Object -ComObject Outlook.Application
        $Mail = $Outlook.CreateItem(0)

        $Mail.To = $EmailTo
        $Mail.Subject = "📊 MIE ePCV - Hourly Summary"

        if ((Test-Path $LogFile) -and ((Get-Content $LogFile).Count -gt 0)) {

            $logText = (Get-Content $LogFile) -join "`n"

            $body = @"
<html>
<body>
<h2>Failures in Last Hour</h2>
<pre>$logText</pre>
</body>
</html>
"@

        } else {

            $body = "<h2>✔ No failures in last hour</h2>"
        }

        $Mail.HTMLBody = $body
        $Mail.Send()

        Write-Host "📊 SUMMARY EMAIL SENT"

        $LastReportTime = Get-Date
    }

    $run++

    # WAIT 5 MINUTES
    Start-Sleep -Seconds 300
}