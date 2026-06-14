# 💿 Disc Rescue Bot 🚀

[![Bash Shell](https://img.shields.io/badge/shell-bash-4ea94b.svg)](https://www.gnu.org/software/bash/)
[![HomeLab Friendly](https://img.shields.io/badge/HomeLab-Approved-orange.svg)]()

**Disc Rescue Bot** is a system-level automated Bash script designed for bulk data recovery from old, degraded, or scratched CDs, DVDs, and optical media (perfect for fighting *CD Rot*). It is fully optimized for headless environments—such as Virtual Machines or LXC Containers on **Proxmox VE**—and handles the entire ripping workflow without requiring any keyboard interaction.

Just insert a disc: the script automatically detects it, initiates an advanced hardware-level recovery phase, sends a real-time push notification to your smartphone when done, and ejects the tray while waiting for the next disc.

---

## ✨ Key Features

* **🧠 Smart Data Recovery (`ddrescue`):** Instead of standard copy commands (which freeze or fail on bad sectors), it leverages GNU `ddrescue`. It quickly maps out healthy sectors first, then goes back to scrape damaged areas to recover maximum data without wearing down the optical drive's laser.
* **📱 Real-Time Push Notifications:** Native integration for **Telegram** and **Discord** using richly formatted messages and emojis. Get a ping on your phone the moment a disc is completed.
* **📜 Professional Logging:** Generates a centralized log file (`ripping_session.log`) with precise timestamps and log levels (`[INFO]`, `[SUCCESS]`, `[WARNING]`). The raw, detailed output of the underlying recovery tool is captured inside for deep auditing.
* **🤖 100% Headless Automation:** Automatic polling loop detects media insertion and physically ejects the tray once processing finishes.

---

## 🛠️ Prerequisites

Before running the script, ensure that the required packages are installed on your Linux system (Debian/Ubuntu/Proxmox LXC):

```bash
sudo apt update && sudo apt install gddrescue curl eject -y
```
## How to run
```bash
TARGET_DIR="/mnt/storage4tb/archive" \
TELEGRAM_BOT_TOKEN="123456:ABCdefGh..." \
TELEGRAM_CHAT_ID="987654321" \
DISCORD_WEBHOOK_URL="[https://discord.com/api/webhooks/](https://discord.com/api/webhooks/)..." \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MrCapo/headless-cd-ripper/main/ripper.sh)"
