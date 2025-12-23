# ⚡ LazyAdmin: The Ultimate Windows SysAdmin Suite

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-3.0%20Enterprise-orange)

> **"I choose a lazy person to do a hard job. Because a lazy person will find an easy way to do it."** - Bill Gates

**LazyAdmin** is a comprehensive, GUI-based automation tool designed for IT Support Specialists and System Administrators. It turns complex PowerShell commands into a simple, one-click experience.

From batch software installation (via JSON-driven Winget) to deep system maintenance and network troubleshooting, LazyAdmin does the heavy lifting so you don't have to.

---

## 🚀 Key Features

### 1. 📊 Real-Time Dashboard
Get an instant overview of the system health:
* **System Uptime & OS Version**
* **Disk Usage (C:) & S.M.A.R.T Health Status**
* **RAM Utilization**

### 2. 🛍️ Dynamic Software Shop (Winget Engine)
Forget manual installers! LazyAdmin features a **JSON-driven** software market.
* **Configurable:** Edit `apps.json` to add your own favorite apps.
* **Batch Install:** Select Chrome, VS Code, Zoom, and 7-Zip, then click one button to install them all silently.

### 3. 🛠️ Admin Ops & Maintenance
Corporate-grade tools for everyday tickets:
* **Teams & Edge Cache Cleaner:** Fixes login/glitch issues instantly.
* **Active Directory Queries:** Get user groups and members (requires RSAT).
* **System Repair:** One-click `SFC /Scannow` and Temp file cleanup.

### 4. 🌐 Network God Mode
Troubleshoot connectivity like a pro:
* **Wi-Fi Revealer:** Display saved Wi-Fi passwords in plain text.
* **Connectivity Test:** Instant Google Ping & Latency check.
* **Fix Network:** Flush DNS, Release/Renew IP stack in one click.

---

## 📦 Installation & Usage

### Prerequisites
* Windows 10 or Windows 11
* PowerShell 5.1 or later
* Administrator Privileges (Required for maintenance tasks)

### How to Run

1.  **Clone the Repository**
    ```powershell
    git clone [https://github.com/YOUR_USERNAME/LazyAdmin.git](https://github.com/YOUR_USERNAME/LazyAdmin.git)
    cd LazyAdmin
    ```

2.  **Unblock the Script (If needed)**
    Windows might block scripts downloaded from the internet. Run this once:
    ```powershell
    Unblock-File .\LazyAdmin_v3.ps1
    ```

3.  **Run the Tool**
    Right-click `LazyAdmin_v3.ps1` and select **"Run with PowerShell"**.
    *Note: It is recommended to run as Administrator for full functionality.*

---

## ⚙️ Configuration (The Magic Part)

LazyAdmin is **Data-Driven**. You don't need to touch the code to change the software list. Just edit the `apps.json` file in the root folder:

```json
[
  {
    "Category": "Browsers",
    "Name": "Brave Browser",
    "Id": "Brave.Brave",
    "Description": "Privacy-first browser."
  }
]
