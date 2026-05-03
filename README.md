# MIE ePCV Monitoring Bot

A lightweight monitoring tool that automatically checks the availability and login functionality of the MIE ePCV system.

## 🚀 Features

* Logs into the target website using automated browser (Playwright)
* Detects:

  * Site downtime
  * Login failures
  * UI issues (missing elements)
  * Timeouts
* Captures screenshots on failure
* Sends real-time email alerts
* Generates hourly summary reports of failures
* Continuous monitoring (runs every 5 minutes)

---

## 🛠️ Tech Stack

* Node.js (Playwright)
* PowerShell
* Microsoft Outlook (for email alerts)

---

## 📁 Project Structure

mie-monitor/
├── script.js        # Playwright automation (login + checks)
├── script.ps1       # Monitoring loop + email alerts
├── .gitignore
└── README.md

---

## ⚙️ Setup Instructions

### 1. Install Requirements

* Install Node.js

* Install Playwright:
  npm install playwright

* Ensure Microsoft Outlook is installed (required for email alerts)

---

### 2. Set Environment Variables

In PowerShell:

$env:MIE_USERNAME="your_username"
$env:MIE_PASSWORD="your_password"
$env:MIE_URL="https://epcv.mie.co.za/Account/Login"

$env:ALERT_EMAIL="[your@email.com](mailto:your@email.com)"
$env:NODE_SCRIPT_PATH="C:\path\to\script.js"
$env:SCREENSHOT_DIR="C:\path\to\screenshots"

---

### 3. Run the Monitor

powershell -ExecutionPolicy Bypass -File script.ps1

---

## 📸 Screenshots

Screenshots are automatically saved when failures occur.

---

## 📊 Alerts

### Immediate Alerts

Sent when:

* Site is down
* Login fails
* Timeout occurs
* UI is broken

### Hourly Summary

* Sends a report of all failures in the past hour

---

## 🔒 Security

* Credentials are NOT stored in the code
* Uses environment variables for all sensitive data
* `.gitignore` prevents sensitive/local files from being uploaded

---

## ⚠️ Notes

* This script is designed for Windows environments
* Requires Microsoft Outlook for sending emails
* Uses Microsoft Edge via Playwright

---

## 📌 Future Improvements

* Add retry logic for transient failures
* Add response time tracking
* Integrate with external alerting systems (Slack, Teams, etc.)
* Docker support for portability

---

## 📄 License

This project is for internal/educational use.
