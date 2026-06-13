#!/bin/bash

# ==========================================
# --- NOTIFICATION CONFIGURATION (ENV FALLBACK) ---
# ==========================================
# Telegram (Leave empty if not used)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Discord (Leave empty if not used)
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# --- HARDWARE & STORAGE CONFIGURATION ---
DRIVE="${DRIVE:-/dev/sr0}"
TARGET_DIR="${TARGET_DIR:-/mnt/storage/archive}"
LOG_FILE="$TARGET_DIR/ripping_session.log"
COUNTER=1

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# --- PUSH NOTIFICATION FUNCTION ---
send_push_notification() {
    local MESSAGE="$1"
    
    # 1. Send to Telegram (Uses basic Markdown)
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${MESSAGE}" \
            -d "parse_mode=Markdown" > /dev/null 2>&1
    fi

    # 2. Send to Discord (Uses standard JSON payload)
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        # Escape quotation marks for JSON safety
        local ESCAPED_MSG=$(echo "$MESSAGE" | sed 's/"/\\"/g')
        curl -s -H "Content-Type: application/json" \
            -X POST \
            -d "{\"content\": \"${ESCAPED_MSG}\"}" \
            "${DISCORD_WEBHOOK_URL}" > /dev/null 2>&1
    fi
}

# --- LOGGING FUNCTION ---
log_action() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    local LOG_ENTRY="[$TIMESTAMP] [$LEVEL] $MESSAGE"
    
    # Print to stdout and append to logfile simultaneously
    echo "$LOG_ENTRY" | tee -a "$LOG_FILE"
}

# --- SCRIPT EXECUTION ENGINE ---
clear
log_action "INFO" "=== AUTOMATIC DISK COPIER INITIALIZED ==="
log_action "INFO" "Target destination set to: $TARGET_DIR"
log_action "INFO" "Hardware polling active on drive: $DRIVE"

# Session Startup Notification
send_push_notification "🚀 *Automatic Disk Copier* started on server!\n📂 Destination: \`$TARGET_DIR\`\n💿 Waiting for the first disc..."

echo "----------------------------------------------------------------"

while true; do
    # Check if the drive is ready and contains valid media
    if dd if="$DRIVE" of=/dev/null bs=2048 count=1 status=none 2>/dev/null; then
        CURRENT_ISO="$TARGET_DIR/CD_${COUNTER}.iso"
        MAPFILE="$TARGET_DIR/CD_${COUNTER}.map"
        
        echo ""
        log_action "INFO" "Disc $COUNTER detected in drive. Starting extraction..."
        log_action "INFO" "Generating image file: CD_${COUNTER}.iso"
        
        # Dispatch processing push alert
        send_push_notification "💿 *Disc $COUNTER* detected!\n⏳ Hardware-level extraction and analysis started..."
        
        echo "--> Analyzing and recovering (Running in background)..."
        
        # Execute ddrescue routing verbose output to logfile
        # -d: Direct disc access (bypasses OS kernel cache)
        # -r3: Triggers a maximum of 3 retry passes on bad sectors
        echo "=== DDRESCUE OUTPUT FOR CD $COUNTER ===" >> "$LOG_FILE"
        ddrescue -d -r3 "$DRIVE" "$CURRENT_ISO" "$MAPFILE" >> "$LOG_FILE" 2>&1
        EXIT_CODE=$?
        echo "========================================" >> "$LOG_FILE"
        
        # Evaluate processing exit code
        if [ $EXIT_CODE -eq 0 ]; then
            log_action "SUCCESS" "Disc $COUNTER successfully cloned."
            # Remove mapfile on perfect copy to keep directory clean
            rm -f "$MAPFILE"
            
            # Success Push Notification
            send_push_notification "✅ *Disc $COUNTER completed!*\n📊 Status: 100% Success (0 bad sectors found).\n📥 Drive tray ejected. Please insert Disc $((COUNTER+1))."
        else
            log_action "WARNING" "Disc $COUNTER completed with alerts (Exit Code: $EXIT_CODE)."
            log_action "WARNING" "Some sectors might be degraded. Mapfile preserved for auditing: CD_${COUNTER}.map"
            
            # Warning Push Notification
            send_push_notification "⚠️ *Disc $COUNTER finished with ALERTS!*\n📊 Status: Media might be scratched or contains unreadable sectors.\n📝 Check the logfile on the server.\n📥 Drive tray ejected."
        fi
        
        # Hardware alert beep and physical tray ejection
        echo -e "\a" 
        log_action "INFO" "Executing drive tray physical ejection command..."
        eject "$DRIVE"
        
        log_action "INFO" "Session cycle for Disc $COUNTER finalized."
        echo "----------------------------------------------------------------"
        
        COUNTER=$((COUNTER+1))
        log_action "INFO" "Ready for next input. Requested: Disc $COUNTER"
    fi
    
    # 5-second polling interval to prevent I/O bus
    sleep 5
done
